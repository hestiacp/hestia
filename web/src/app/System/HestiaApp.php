<?php

declare(strict_types=1);

namespace Hestia\System;
use Exception;
use RuntimeException;
use Symfony\Component\Process\Process;
use function array_unshift;
use function chmod;
use function Hestiacp\quoteshellarg\quoteshellarg;
use function is_file;
use function trigger_error;
use function unlink;
use const DIRECTORY_SEPARATOR;

class HestiaApp {
	/** @var string[] */
	public $errors;
	protected const TMPDIR_DOWNLOADS = "/tmp/hestia-webapp";
	protected $phpsupport = false;

	public function __construct() {
		@mkdir(self::TMPDIR_DOWNLOADS);
	}

	public function addDirectory(string $path): void
	{
		$result = $this->runUser("v-add-fs-directory", [$path]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(sprintf('Failed to add directory "%s"', $path));
		}
	}

	public function copyDirectory(string $fromPath, string $toPath): void
	{
		$result = $this->runUser("v-copy-fs-directory", [$fromPath, $toPath]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(
				sprintf('Failed to copy directory "%s" to "%s"', $fromPath, $toPath)
			);
		}
	}

	public function deleteDirectory(string $path): void
	{
		$result = $this->runUser("v-delete-fs-directory", [$path]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(sprintf('Failed to remove directory "%s"', $path));
		}
	}

	public function createFile(string $path, string $contents): void
	{
		$tmpFile = tempnam("/tmp", "hst.");

		if (!$tmpFile) {
			throw new RuntimeException("Error creating temp file");
		}

		if (!file_put_contents($tmpFile, $contents)) {
			throw new RuntimeException("Error writing to temp file");
		}

		chmod($tmpFile, 0644);

		$this->runUser("v-copy-fs-file", [$tmpFile, $path]);

		unlink($tmpFile);
	}

	public function moveFile(string $fromPath, string $toPath): void
	{
		$result = $this->runUser("v-move-fs-file", [$fromPath, $toPath]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(
				sprintf('Failed to move file "%s" to "%s"', $fromPath, $toPath)
			);
		}
	}

	public function changeFilePermissions(string $filePath, string $permission): void
	{
		$result = $this->runUser("v-change-fs-file-permission", [$filePath, $permission]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(
				sprintf('Failed to change file "%s" permissions to "%s"', $filePath, $permission)
			);
		}
	}

	public function deleteFile(string $filePath): void
	{
		$result = $this->runUser("v-delete-fs-file", [$filePath]);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(sprintf('Failed to delete file "%s"', $filePath));
		}
	}

	public function sendPostRequest($url, array $formData, array $headers = []): void
	{
		$ch = curl_init($url);

		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
		curl_setopt($ch, CURLOPT_MAXREDIRS, 3);
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($ch, CURLOPT_POST, true);
		curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($formData));

		if ($headers !== []) {
			curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
		}

		curl_exec($ch);

		$error = curl_error($ch);
		$errno = curl_errno($ch);

		curl_close($ch);

		if (0 !== $errno) {
			throw new RuntimeException($error, $errno);
		}
	}

	public function runComposer($phpVersion, $args): HestiaCommandResult {
		$this->runUser("v-add-user-composer", []);

		$composerBin = $this->getUserHomeDir() . "/.composer/composer";

		return $this->runPHP($phpVersion, $composerBin, $args);
	}

	public function runWp($phpVersion, $args): HestiaCommandResult {
		$this->runUser("v-add-user-wp-cli", []);

		$wpCliBin = $this->getUserHomeDir() . "/.wp-cli/wp";

		return $this->runPHP($phpVersion, $wpCliBin, $args);
	}

	public function runPHP(string $phpVersion, string $command, array $arguments): HestiaCommandResult
	{
		$phpCommand = [
			"/usr/bin/php" . $phpVersion,
			$command,
			...$arguments,
		];

		$result = $this->runUser("v-run-cli-cmd", $phpCommand);

		if ($result->exitCode !== 0) {
			throw new RuntimeException(
				sprintf('Failed to run php command "%s"', $result->command)
			);
		}

		return $result;
	}

	public function runUser(string $cmd, array $args): HestiaCommandResult {
		return $this->run($cmd, [$this->user(), ...$args]);
	}

	// Effective user
	public function user(): string {
		$user = $_SESSION["user"];

		if ($_SESSION["userContext"] === "admin" && !empty($_SESSION["look"])) {
			$user = $_SESSION["look"];
		}

		if (strpos($user, DIRECTORY_SEPARATOR) !== false) {
			throw new Exception("illegal characters in username");
		}
		return $user;
	}

	public function getUserHomeDir() {
		$info = posix_getpwnam($this->user());
		return $info["dir"];
	}

	public function userOwnsDomain(string $domain): bool {
		$result = $this->runUser("v-list-web-domain", [$domain, "json"]);

		return $result->exitCode === 0;
	}

	public function checkDatabaseLimit(): bool {
		$result = $this->runUser("v-list-user", ["json"]);

		$userInfo = $result->getOutputJson()[$this->user()];

		return $userInfo["DATABASES"] === "unlimited"
			|| ($userInfo["DATABASES"] - $userInfo["U_DATABASES"]) < 1;
	}
	public function databaseAdd(
		string $dbname,
		string $dbuser,
		string $dbpass,
		string $dbtype = "mysql",
		string $dbhost = "localhost",
		string $charset = "utf8mb4",
	) {
		$v_password = tempnam("/tmp", "hst");
		$fp = fopen($v_password, "w");
		fwrite($fp, $dbpass . "\n");
		fclose($fp);
		$status = $this->runUser("v-add-database", [
			$dbname,
			$dbuser,
			$v_password,
			$dbtype,
			$dbhost,
			$charset,
		]);
		if ($status->exitCode !== 0) {
			$this->errors[] = _("Unable to add database!");
		}
		unlink($v_password);
		return $status;
	}

	public function getCurrentBackendTemplate(string $domain) {
		$result = $this->runUser("v-list-web-domain", [$domain, "json"]);
		$version = $result->getOutputJson()[$domain]["BACKEND"];
		if (!empty($version)) {
			if ($version != "default") {
				$test = preg_match("/^.*PHP-([0-9])\_([0-9])/", $version, $match);
				return $match[1] . "." . $match[2];
			} else {
				$result = $this->run("v-list-sys-php", ["json"]);
				return $result->getOutputJson()[0];
			}
		} else {
			$result = $this->run("v-list-sys-php", ["json"]);
			return $result->getOutputJson()[0];
		}
	}

	public function changeWebTemplate(string $domain, string $template) {
		$status = $this->runUser("v-change-web-domain-tpl", [$domain, $template]);
	}
	public function changeBackendTemplate(string $domain, string $template) {
		$status = $this->runUser("v-change-web-domain-backend-tpl", [$domain, $template]);
	}

	public function listSuportedPHP() {
		if (!$this->phpsupport) {
			$result = $this->run("v-list-sys-php", ["json"]);
			$this->phpsupport = $result->getOutputJson();
		}
		return $this->phpsupport;
	}

	/*
		Return highest available supported php version
		Eg: Package requires: 7.3 or 7.4 and system has 8.0 and 7.4 it will return 7.4
				Package requires: 8.0 or 8.1 and system has 8.0 and 7.4 it will return 8.0
				Package requires: 7.4 or 8.0 and system has 8.0 and 7.4 it will return 8.0
				If package isn't supported by the available php version false will returned
		*/
	public function getSupportedPHP($support) {
		$versions = $this->listSuportedPHP();
		$supported = false;
		$supported_versions = [];

		foreach ($versions as $version) {
			if (in_array($version, $support)) {
				$supported = true;
				$supported_versions[] = $version;
			}
		}
		if ($supported) {
			return $supported_versions;
		} else {
			return false;
		}
	}

	public function getWebDomain(string $domainName): WebDomain
	{
		$result = $this->runUser("v-list-web-domain", [$domainName, "json"]);

		if ($result->exitCode !== 0) {
			throw new Exception("Cannot find domain for user");
		}

		return new WebDomain(
			$domainName,
			Util::join_paths($this->getUserHomeDir(), "web", $domainName),
			filter_var($result->getOutputJson()[$domainName]["IP"], FILTER_VALIDATE_IP),
			$result->getOutputJson()[$domainName]["SSL"] === "yes"
		);
	}

	public function getWebDomainPath(string $domain) {
		return Util::join_paths($this->getUserHomeDir(), "web", $domain);
	}

	public function downloadUrl(string $src, $path = null, &$result = null) {
		if (strpos($src, "http://") !== 0 && strpos($src, "https://") !== 0) {
			return false;
		}

		exec(
			"/usr/bin/wget --tries 3 --timeout=30 --no-dns-cache -nv " .
				quoteshellarg($src) .
				" -P " .
				quoteshellarg(self::TMPDIR_DOWNLOADS) .
				" 2>&1",
			$output,
			$return_var,
		);
		if ($return_var !== 0) {
			return false;
		}

		if (
			!preg_match(
				'/URL:\s*(.+?)\s*\[(.+?)\]\s*->\s*"(.+?)"/',
				implode(PHP_EOL, $output),
				$matches,
			)
		) {
			return false;
		}

		if (empty($matches) || count($matches) != 4) {
			return false;
		}

		$status["url"] = $matches[1];
		$status["file"] = $matches[3];
		$result = (object) $status;
		return true;
	}

	public function archiveExtract(string $src, string $path, $skip_components = null) {
		if (empty($path)) {
			throw new Exception("Error extracting archive: missing target folder");
		}

		if (realpath($src)) {
			$archive_file = $src;
		} else {
			if (!$this->downloadUrl($src, null, $download_result)) {
				throw new Exception("Error downloading archive");
			}
			$archive_file = $download_result->file;
		}

		$result = $this->runUser("v-extract-fs-archive", [
			$archive_file,
			$path,
			null,
			$skip_components,
		]);
		unlink($archive_file);

		return $result;
	}

	public function cleanupTmpDir(): void {
		$files = glob(self::TMPDIR_DOWNLOADS . "/*");
		foreach ($files as $file) {
			if (is_file($file)) {
				unlink($file);
			}
		}
	}

	public function __destruct() {
		$this->cleanupTmpDir();
	}

	private function run(string $cmd, array $args): HestiaCommandResult
	{
		$cli_script = realpath(HESTIA_DIR_BIN . $cmd);

		$command = [
			'/usr/bin/sudo',
			$cli_script,
			...$args,
		];

		$process = new Process($command);
		$process->run();

		if (!$process->isSuccessful()) {
			//log error message in nginx-error.log
			trigger_error($process->getCommandLine() . " | " . $process->getOutput());
			//throw exception if command fails
			throw new RuntimeException($process->getErrorOutput());
		}

		return new HestiaCommandResult(
			$process->getCommandLine(),
			$process->getExitCode(),
			$process->getOutput(),
		);
	}
}
