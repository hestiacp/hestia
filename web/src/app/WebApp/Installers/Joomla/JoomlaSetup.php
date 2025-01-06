<?php

namespace Hestia\WebApp\Installers\Joomla;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

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
				"supported" => ["7.4", "8.0", "8.1", "8.2"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::setInstallationDirectory($options["install_directory"] ?? "");
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		// Database credentials
		$dbHost = $options["database_host"];
		$dbName = $this->appcontext->user() . "_" . $options["database_name"];
		$dbUser = $this->appcontext->user() . "_" . $options["database_user"];
		$dbPass = $options["database_password"];

		// Site and admin credentials
		$siteName = $options["site_name"];
		$adminUsername = $options["admin_username"];
		$adminPassword = $options["admin_password"];
		$adminEmail = $options["admin_email"];

		// Initialize Joomla using the CLI
		$cliCmd = [
			"/usr/bin/php",
			quoteshellarg($installationTarget->getDocRoot("/installation/joomla.php")),
			"install",
			"--site-name=" . quoteshellarg($siteName),
			"--admin-user=" . quoteshellarg($adminUsername),
			"--admin-username=" . quoteshellarg($adminUsername),
			"--admin-password=" . quoteshellarg($adminPassword),
			"--admin-email=" . quoteshellarg($adminEmail),
			"--db-user=" . quoteshellarg($dbUser),
			"--db-pass=" . quoteshellarg($dbPass),
			"--db-name=" . quoteshellarg($dbName),
			"--db-prefix=" . quoteshellarg(Util::generate_string(5, false) . "_"),
			"--db-host=" . quoteshellarg($dbHost),
			"--db-type=mysqli",
		];

		$status = null;
		$this->appcontext->runUser("v-run-cli-cmd", $cliCmd, $status);

		if ($status->code !== 0) {
			throw new \Exception("Failed to install Joomla using CLI: " . $status->text);
		}

		return true;
	}
}
