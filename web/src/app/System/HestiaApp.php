<?php

declare(strict_types=1);

namespace Hestia\System;
use RuntimeException;
use function Hestiacp\quoteshellarg\quoteshellarg;

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
		$status = null;

		$this->runUser(
			"v-add-fs-directory",
			[$path],
			$status,
		);

		if ($status->code !== 0) {
			throw new RuntimeException(
				sprintf('Failed to add directory "%s"', $path)
			);
		}
	}

	public function copyDirectory(string $fromPath, string $toPath): void
	{
		$status = null;

		$this->runUser(
			"v-copy-fs-directory",
			[$fromPath, $toPath],
			$status,
		);

		if ($status->code !== 0) {
			throw new RuntimeException(
				sprintf('Failed to copy directory "%s" to "%s"', $fromPath, $toPath)
			);
		}
	}

	public function moveFile(string $fromPath, string $toPath): void
	{
		$status = null;

		$this->runUser(
			"v-move-fs-file",
			[$fromPath, $toPath],
			$status,
		);

		if ($status->code !== 0) {
			throw new RuntimeException(
				sprintf('Failed to move file "%s" to "%s"', $fromPath, $toPath)
			);
		}
	}

	public function changeFilePermissions(string $filePath, string $permission): void
	{
		$status = null;

		$this->runUser(
			"v-change-fs-file-permission",
			[$filePath, $permission],
			$status,
		);

		if ($status->code !== 0) {
			throw new RuntimeException(
				sprintf('Failed to change file "%s" permissions to "%s"', $filePath, $permission)
			);
		}
	}

	public function deleteFile(string $filePath): void
	{
		$status = null;

		$this->runUser(
			"v-delete-fs-file",
			[$filePath],
			$status,
		);

		if ($status->code !== 0) {
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

	public function runUser(string $cmd, $args, &$cmd_result = null): bool {
		if (!empty($args) && is_array($args)) {
			array_unshift($args, $this->user());
		} else {
			$args = [$this->user(), $args];
		}
		return $this->run($cmd, $args, $cmd_result);
	}

	public function installComposer($version) {
		exec("curl https://composer.github.io/installer.sig", $output);

		$signature = implode(PHP_EOL, $output);
		if (empty($signature)) {
			throw new \Exception("Error reading composer signature");
		}

		$composer_setup =
			self::TMPDIR_DOWNLOADS . DIRECTORY_SEPARATOR . "composer-setup-" . $signature . ".php";

		exec(
			"wget https://getcomposer.org/installer --quiet -O " . quoteshellarg($composer_setup),
			$output,
			$return_code,
		);
		if ($return_code !== 0) {
			throw new \Exception("Error downloading composer");
		}

		if ($signature !== hash_file("sha384", $composer_setup)) {
			unlink($composer_setup);
			throw new \Exception("Invalid composer signature");
		}

		$install_folder = $this->getUserHomeDir() . DIRECTORY_SEPARATOR . ".composer";

		if (!file_exists($install_folder)) {
			exec(HESTIA_CMD . "v-rebuild-user " . $this->user(), $output, $return_code);
			if ($return_code !== 0) {
				throw new \Exception("Unable to rebuild user");
			}
		}

		$this->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php",
				$composer_setup,
				"--quiet",
				"--install-dir=" . $install_folder,
				"--filename=composer",
				"--$version",
			],
			$status,
		);

		unlink($composer_setup);

		if ($status->code !== 0) {
			throw new \Exception("Error installing composer");
		}
	}

	public function updateComposer($version) {
		$this->runUser("v-run-cli-cmd", ["composer", "selfupdate", "--$version"]);
	}

	public function runComposer($args, &$cmd_result = null, $data = []): bool {
		$composer =
			$this->getUserHomeDir() .
			DIRECTORY_SEPARATOR .
			".composer" .
			DIRECTORY_SEPARATOR .
			"composer";
		if (!is_file($composer)) {
			$this->installComposer($data["version"]);
		} else {
			$this->updateComposer($data["version"]);
		}
		if (empty($data["php_version"])) {
			$data["php_version"] = "";
		}
		if (!empty($args) && is_array($args)) {
			array_unshift($args, "php" . $data["php_version"], $composer);
		} else {
			$args = ["php" . $data["php_version"], $composer, $args];
		}

		return $this->runUser("v-run-cli-cmd", $args, $cmd_result);
	}

	public function runWp($args, &$cmd_result = null): bool {
		$wp =
			$this->getUserHomeDir() . DIRECTORY_SEPARATOR . ".wp-cli" . DIRECTORY_SEPARATOR . "wp";
		if (!is_file($wp)) {
			$this->runUser("v-add-user-wp-cli", []);
		} else {
			$this->runUser("v-run-cli-cmd", [$wp, "cli", "update", "--yes"]);
		}
		array_unshift($args, $wp);

		return $this->runUser("v-run-cli-cmd", $args, $cmd_result);
	}

	// Logged in user
	public function realuser(): string {
		return $_SESSION["user"];
	}

	// Effective user
	public function user(): string {
		$user = $this->realuser();
		if ($_SESSION["userContext"] === "admin" && !empty($_SESSION["look"])) {
			$user = $_SESSION["look"];
		}

		if (strpos($user, DIRECTORY_SEPARATOR) !== false) {
			throw new \Exception("illegal characters in username");
		}
		return $user;
	}

	public function getUserHomeDir() {
		$info = posix_getpwnam($this->user());
		return $info["dir"];
	}

	public function userOwnsDomain(string $domain): bool {
		return $this->runUser("v-list-web-domain", [$domain, "json"]);
	}

	public function checkDatabaseLimit() {
		$status = $this->runUser("v-list-user", ["json"], $result);
		$result->json[$this->user()];
		if ($result->json[$this->user()]["DATABASES"] != "unlimited") {
			if (
				$result->json[$this->user()]["DATABASES"] -
					$result->json[$this->user()]["U_DATABASES"] <
				1
			) {
				return false;
			}
		}
		return true;
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
		if (!$status) {
			$this->errors[] = _("Unable to add database!");
		}
		unlink($v_password);
		return $status;
	}

	public function getCurrentBackendTemplate(string $domain) {
		$status = $this->runUser("v-list-web-domain", [$domain, "json"], $return_message);
		$version = $return_message->json[$domain]["BACKEND"];
		if (!empty($version)) {
			if ($version != "default") {
				$test = preg_match("/^.*PHP-([0-9])\_([0-9])/", $version, $match);
				return $match[1] . "." . $match[2];
			} else {
				$supported = $this->run("v-list-sys-php", "json", $result);
				return $result->json[0];
			}
		} else {
			$supported = $this->run("v-list-sys-php", "json", $result);
			return $result->json[0];
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
			$status = $this->run("v-list-sys-php", "json", $result);
			$this->phpsupport = $result->json;
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
		$result = null;

		$this->runUser(
			"v-list-web-domain",
			[$domainName, "json"],
			$result,
		);

		if ($result === null && $result->code !== 0) {
			throw new \Exception("Cannot find domain for user");
		}

		return new WebDomain(
			$domainName,
			Util::join_paths($this->getUserHomeDir(), "web", $domainName),
			filter_var($result->json[$domainName]["IP"], FILTER_VALIDATE_IP),
			$result->json[$domainName]["SSL"] === "yes"
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
			throw new \Exception("Error extracting archive: missing target folder");
		}

		if (realpath($src)) {
			$archive_file = $src;
		} else {
			if (!$this->downloadUrl($src, null, $download_result)) {
				throw new \Exception("Error downloading archive");
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

	private function run(string $cmd, $args, &$cmd_result = null): bool {
		$cli_script = realpath(HESTIA_DIR_BIN . $cmd);
		if (!str_starts_with((string) $cli_script, HESTIA_DIR_BIN)) {
			$errstr = "$cmd is trying to traverse outside of " . HESTIA_DIR_BIN;
			trigger_error($errstr);
			throw new \Exception($errstr);
		}
		$cli_script = "/usr/bin/sudo " . quoteshellarg($cli_script);

		$cli_arguments = "";
		if (!empty($args) && is_array($args)) {
			foreach ($args as $arg) {
				$cli_arguments .= quoteshellarg((string) $arg) . " ";
			}
		} else {
			$cli_arguments = quoteshellarg($args);
		}

		exec($cli_script . " " . $cli_arguments . " 2>&1", $output, $exit_code);

		$result["code"] = $exit_code;
		$result["args"] = $cli_arguments;
		$result["raw"] = $output;
		$result["text"] = implode(PHP_EOL, $output);
		$result["json"] = json_decode($result["text"], true);
		$cmd_result = (object) $result;
		if ($exit_code > 0) {
			//log error message in nginx-error.log
			trigger_error($cli_script . " " . $cli_arguments . " | " . $result["text"]);
			//throw exception if command fails
			throw new \Exception($result["text"]);
		}
		return $exit_code === 0;
	}
}
