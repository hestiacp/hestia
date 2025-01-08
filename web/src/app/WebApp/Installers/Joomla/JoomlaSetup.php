<?php

namespace Hestia\WebApp\Installers\Joomla;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;

class JoomlaSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Joomla",
		"group" => "cms",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "joomla_thumb.png",
	];

	protected $config = [
		"form" => [
			"site_name" => [
				"type" => "text",
				"value" => "Joomla Site",
				"placeholder" => "Joomla Site",
			],
			"admin_username" => [
				"type" => "text",
				"value" => "admin",
				"placeholder" => "Admin Username",
			],
			"admin_password" => [
				"type" => "password",
				"value" => "",
				"placeholder" => "Admin Password",
			],
			"admin_email" => [
				"type" => "text",
				"value" => "admin@example.com",
				"placeholder" => "Admin Email",
			],
			"install_directory" => [
				"type" => "text",
				"value" => "",
				"placeholder" => "/",
			],
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" => "https://www.joomla.org/latest",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "joomla",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1", "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::setInstallationDirectory($options["install_directory"] ?? "");
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runPHP(
			$options["php_version"],
			$installationTarget->getDocRoot("/installation/joomla.php"),
			[
				"install",
				"--site-name=" . $options["site_name"],
				"--admin-user=" . $options["admin_username"],
				"--admin-username=" . $options["admin_username"],
				"--admin-password=" . $options["admin_password"],
				"--admin-email=" . $options["admin_email"],
				"--db-user=" . $this->appcontext->user() . "_" . $options["database_user"],
				"--db-pass=" . $options["database_password"],
				"--db-name=" . $this->appcontext->user() . "_" . $options["database_name"],
				"--db-prefix=" . 'jl' . Util::generate_string(5, false) . "_",
				"--db-host=" . $options["database_host"],
				"--db-type=mysqli",
			]
		);
	}
}
