<?php

namespace Hestia\WebApp\Installers\ThirtyBees;

use Hestia\WebApp\Installers\BaseSetup;

class ThirtyBeesSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "ThirtyBees",
		"group" => "ecommerce",
		"enabled" => true,
		"version" => "1.5.1",
		"thumbnail" => "thirtybees-thumb.png",
	];

	protected $extractsubdir = ".";

	protected $config = [
		"form" => [
			"thirtybees_account_first_name" => ["value" => ""],
			"thirtybees_account_last_name" => ["value" => ""],
			"thirtybees_account_email" => "text",
			"thirtybees_account_password" => "password",
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" => "https://github.com/thirtybees/thirtybees/releases/download/1.6.0/thirtybees-v1.6.0-php7.4.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "prestashop",
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

		$this->appcontext->runPHP(
			$options["php_version"],
			$installationTarget->getDocRoot("/install/index_cli.php"),
			[
				"--db_server=" . $options["database_host"],
				"--db_user=" . $this->appcontext->user() . "_" . $options["database_user"],
				"--db_password=" . $options["database_password"],
				"--db_name=" . $this->appcontext->user() . "_" . $options["database_name"],
				"--firstname=" . $options["thirtybees_account_first_name"],
				"--lastname=" . $options["thirtybees_account_last_name"],
				"--password=" . $options["thirtybees_account_password"],
				"--email=" . $options["thirtybees_account_email"],
				"--domain=" . $installationTarget->domainName,
				"--ssl=" . $installationTarget->isSslEnabled,
			]
		);

		$this->appcontext->deleteDirectory($installationTarget->getDocRoot("/install"));
	}
}
