<?php

namespace Hestia\WebApp\Installers;

use Exception;
use Hestia\System\HestiaApp;
use Hestia\System\Util;
use Hestia\WebApp\InstallationTarget;
use Hestia\WebApp\InstallerInterface;
use Hestia\WebApp\Installers\Resources\ComposerResource;
use Hestia\WebApp\Installers\Resources\WpResource;
use function var_dump;

abstract class BaseSetup implements InstallerInterface {
	protected $appInfo;
	protected $config;
	private $domain;
	protected $extractsubdir;
	protected $installationDirectory = '';
	protected $appcontext;

	public function __construct($domain, HestiaApp $appcontext) {
		if (filter_var($domain, FILTER_VALIDATE_DOMAIN) === false) {
			throw new Exception("Invalid domain name");
		}

		$this->domain = $domain;
		$this->appcontext = $appcontext;
	}

	public function setInstallationDirectory(string $installationDirectory) {
		if (!empty($installationDirectory)) {
			if (strpos(".", $installationDirectory) !== false) {
				throw new Exception("Invalid install folder");
			}
			if (!is_dir($this->getDocRoot($installationDirectory))) {
				$this->appcontext->addDirectory($this->getDocRoot($installationDirectory));
			}
			$this->installationDirectory = $installationDirectory;
		}
	}

	public function getInstallationDirectory() {
		return $this->installationDirectory;
	}

	public function info() {
		$this->appInfo["enabled"] = true;
		if (isset($this->config["server"]["php"]["supported"])) {
			$this->appInfo["php_support"] = $this->config["server"]["php"]["supported"];
		} else {
			$this->appInfo["php_support"] = [
				"5.6",
				"7.0",
				"7.1",
				"7.2",
				"7.3",
				"7.4",
				"8.0",
				"8.1",
				"8.2",
				"8.3",
			];
		}
		return $this->appInfo;
	}

	public function getConfig($section = null) {
		return !empty($section) ? $this->config[$section] : $this->config;
	}

	public function getOptions() {
		return $this->getConfig("form");
	}

	public function withDatabase(): bool {
		return $this->getConfig("database") === true;
	}

	public function getInstallationTarget(): InstallationTarget
	{
		$webDomain = $this->appcontext->getWebDomain($this->domain);

		if (empty($webDomain->domainPath) || !is_dir($webDomain->domainPath)) {
			throw new Exception(sprintf(
				"Web domain path '%s' not found for domain '%s'",
				$webDomain->domainPath,
				$webDomain->domainName,
			));
		}

		return new InstallationTarget(
			$webDomain->domainName,
			$webDomain->domainPath,
			$this->installationDirectory,
			$webDomain->ipAddress,
			$webDomain->isSslEnabled,
		);
	}

	public function retrieveResources($options) {
		foreach ($this->getConfig("resources") as $res_type => $res_data) {
			if (!empty($res_data["dst"]) && is_string($res_data["dst"])) {
				$destinationPath = $this->getDocRoot($res_data["dst"]);
			} else {
				$destinationPath = $this->getDocRoot($this->extractsubdir);
			}

			if ($res_type === "composer") {
				$this->appcontext->runComposer(
					$options['php_version'],
					[
						"create-project",
						"--no-progress",
						"--prefer-dist",
						$res_data["src"],
						"-d " . dirname($destinationPath),
						basename($destinationPath),
					],
				);
			} elseif ($res_type === "wp") {
				$this->appcontext->runWp(
					$options['php_version'],
					[
						"core",
						"download",
						"--locale=" . $options["language"],
						"--version=" . $this->info()["version"],
						"--path=" . $destinationPath,
					],
				);
			} else {
				$this->appcontext->archiveExtract($res_data["src"], $destinationPath, 1);
			}
		}
		return true;
	}

	public function setup(array $options = null) {
		if ($_SESSION["WEB_SYSTEM"] == "nginx") {
			if (isset($this->config["server"]["nginx"]["template"])) {
				$this->appcontext->changeWebTemplate(
					$this->domain,
					$this->config["server"]["nginx"]["template"],
				);
			} else {
				$this->appcontext->changeWebTemplate($this->domain, "default");
			}
		} else {
			if (isset($this->config["server"]["apache2"]["template"])) {
				$this->appcontext->changeWebTemplate(
					$this->domain,
					$this->config["server"]["apache2"]["template"],
				);
			} else {
				$this->appcontext->changeWebTemplate($this->domain, "default");
			}
		}
		if ($_SESSION["WEB_BACKEND"] == "php-fpm") {
			if (isset($this->config["server"]["php"]["supported"])) {
				$php_version = $this->appcontext->getSupportedPHP(
					$this->config["server"]["php"]["supported"],
				);
				if (!$php_version) {
					throw new Exception("Required PHP version is not supported");
				}
				//convert from x.x to PHP-x_x to accepted.
				$this->appcontext->changeBackendTemplate(
					$this->domain,
					"PHP-" . str_replace(".", "_", $options["php_version"]),
				);
			}
		}
	}

	public function install(array $options = null) {
		$this->appcontext->deleteFile($this->getDocRoot("robots.txt"));
		$this->appcontext->deleteFile($this->getDocRoot("index.html"));

		return $this->retrieveResources($options);
	}

	public function cleanup() {
		// Remove temporary folder
		if (!empty($this->extractsubdir)) {
			$this->appcontext->deleteDirectory($this->getDocRoot($this->extractsubdir));
		}
	}

	public function saveTempFile(string $data) {
		$tmp_file = tempnam("/tmp", "hst.");
		if (empty($tmp_file)) {
			throw new Exception("Error creating temp file");
		}

		if (file_put_contents($tmp_file, $data) > 0) {
			chmod($tmp_file, 0644);
			$user_tmp_file = Util::join_paths($this->appcontext->getUserHomeDir(), $tmp_file);

			$this->appcontext->moveFile($tmp_file, $user_tmp_file);

			return $user_tmp_file;
		}

		if (file_exists($tmp_file)) {
			unlink($tmp_file);
		}
		return false;
	}

	private function getDocRoot($append_relative_path = null): string {
		$domain_path = $this->appcontext->getWebDomainPath($this->domain);

		if (empty($domain_path) || !is_dir($domain_path)) {
			throw new Exception("Error finding domain folder ($domain_path)");
		}
		if (!$this->installationDirectory) {
			return Util::join_paths($domain_path, "public_html", $append_relative_path);
		}

		return Util::join_paths(
			$domain_path,
			"public_html",
			$this->installationDirectory,
			$append_relative_path,
		);
	}
}
