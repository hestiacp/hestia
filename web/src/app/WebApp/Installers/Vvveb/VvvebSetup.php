<?php

namespace Hestia\WebApp\Installers\Vvveb;

use Hestia\WebApp\Installers\BaseSetup;

class VvvebSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Vvveb",
		"group" => "cms",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "vvveb-symbol.svg",
	];

	protected $config = [
		"form" => [
			"vvveb_account_username" => ["value" => "admin"],
			"vvveb_account_email" => "text",
			"vvveb_account_password" => "password",
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" => "https://www.vvveb.com/latest.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "vvveb",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1", "8.2", "8.3", "8.4"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runPHP(
			$options["php_version"],
			$installationTarget->getDocRoot("/cli.php"),
			[
				"install",
				"host=" . $options["database_host"],
				"user=" . $this->appcontext->user() . "_" . $options["database_user"],
				"password=" . $options["database_password"],
				"database=" . $this->appcontext->user() . "_" . $options["database_name"],
				"admin[user]=" . $options["vvveb_account_username"],
				"admin[password]=" . $options["vvveb_account_password"],
				"admin[email]=" . $options["vvveb_account_email"],
			]
		);
	}
}
