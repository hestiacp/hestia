<?php

namespace Hestia\WebApp\Installers\OpenCart;

use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

class OpenCartSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "OpenCart",
		"group" => "ecommerce",
		"enabled" => true,
		"version" => "4.0.2.2",
		"thumbnail" => "opencart-thumb.png",
	];

	protected $extractsubdir = "/tmp-opencart";

	protected $config = [
		"form" => [
			"opencart_account_username" => ["value" => "ocadmin"],
			"opencart_account_email" => "text",
			"opencart_account_password" => "password",
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" =>
					"https://github.com/opencart/opencart/releases/download/4.0.2.2/opencart-4.0.2.2.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "opencart",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1", "8.2"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runUser(
			"v-copy-fs-directory",
			[
				$installationTarget->getDocRoot($this->extractsubdir . "/upload/."),
				$installationTarget->getDocRoot(),
			],
			$result,
		);

		$this->appcontext->runUser("v-copy-fs-file", [
			$installationTarget->getDocRoot("config-dist.php"),
			$installationTarget->getDocRoot("config.php"),
		]);
		$this->appcontext->runUser("v-copy-fs-file", [
			$installationTarget->getDocRoot("admin/config-dist.php"),
			$installationTarget->getDocRoot("admin/config.php"),
		]);
		$this->appcontext->runUser("v-copy-fs-file", [
			$installationTarget->getDocRoot(".htaccess.txt"),
			$installationTarget->getDocRoot(".htaccess"),
		]);

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				quoteshellarg($installationTarget->getDocRoot("/install/cli_install.php")),
				"install",
				"--db_hostname " . quoteshellarg($options["database_host"]),
				"--db_username " .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_user"]),
				"--db_password " . quoteshellarg($options["database_password"]),
				"--db_database " .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_name"]),
				"--username " . quoteshellarg($options["opencart_account_username"]),
				"--password " . quoteshellarg($options["opencart_account_password"]),
				"--email " . quoteshellarg($options["opencart_account_email"]),
				"--http_server " . quoteshellarg($installationTarget->getUrl() . "/"),
			],
			$status,
		);

		// After install, 'storage' folder must be moved to a location where the web server is not allowed to serve file
		// - Opencart Nginx template and Apache ".htaccess" forbids acces to /storage folder
		$this->appcontext->runUser(
			"v-move-fs-directory",
			[
				$installationTarget->getDocRoot("system/storage"),
				$installationTarget->getDocRoot(),
			],
			$result,
		);
		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"sed",
				"-i",
				"s/'storage\//'..\/storage\// ",
				$installationTarget->getDocRoot("config.php"),
			],
			$status,
		);
		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"sed",
				"-i",
				"s/'storage\//'..\/storage\// ",
				$installationTarget->getDocRoot("admin/config.php"),
			],
			$status,
		);
		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"sed",
				"-i",
				"s/\^system\/storage\//^\/storage\// ",
				$installationTarget->getDocRoot(".htaccess")
			],
			$status,
		);

		$this->appcontext->runUser("v-change-fs-file-permission", [
			$installationTarget->getDocRoot("config.php"),
			"640",
		]);
		$this->appcontext->runUser("v-change-fs-file-permission", [
			$installationTarget->getDocRoot("admin/config.php"),
			"640",
		]);

		// remove install folder
		$this->appcontext->runUser(
			"v-delete-fs-directory",
			[$installationTarget->getDocRoot("/install")],
		);
		$this->cleanup();

		return $status->code === 0;
	}
}
