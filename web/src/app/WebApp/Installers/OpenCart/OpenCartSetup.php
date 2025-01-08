<?php

namespace Hestia\WebApp\Installers\OpenCart;

use Hestia\WebApp\Installers\BaseSetup;

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
				"supported" => ["7.4", "8.0", "8.1", "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->copyDirectory(
			$installationTarget->getDocRoot($this->extractsubdir . "/upload/."),
			$installationTarget->getDocRoot()
		);

		$this->appcontext->moveFile(
			$installationTarget->getDocRoot("config-dist.php"),
			$installationTarget->getDocRoot("config.php"),
		);

		$this->appcontext->moveFile(
			$installationTarget->getDocRoot("admin/config-dist.php"),
			$installationTarget->getDocRoot("admin/config.php"),
		);

		$this->appcontext->moveFile(
			$installationTarget->getDocRoot(".htaccess.txt"),
			$installationTarget->getDocRoot(".htaccess"),
		);

		$this->appcontext->runPHP(
			$options["php_version"],
			$installationTarget->getDocRoot("/install/cli_install.php"),
			[
				"install",
				"--db_hostname",
				$options["database_host"],
				"--db_username",
				$this->appcontext->user() . "_" . $options["database_user"],
				"--db_password",
				$options["database_password"],
				"--db_database",
				$this->appcontext->user() . "_" . $options["database_name"],
				"--username",
				$options["opencart_account_username"],
				"--password",
				$options["opencart_account_password"],
				"--email",
				$options["opencart_account_email"],
				"--http_server",
				$installationTarget->getUrl() . "/",
			]
		);

		$this->appcontext->deleteDirectory($installationTarget->getDocRoot("/install"));
		$this->appcontext->deleteDirectory($installationTarget->getDocRoot($this->extractsubdir));
	}
}
