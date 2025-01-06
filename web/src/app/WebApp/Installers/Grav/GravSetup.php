<?php

namespace Hestia\WebApp\Installers\Grav;

use Hestia\WebApp\Installers\BaseSetup;

class GravSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Grav",
		"group" => "cms",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "grav-symbol.svg",
	];

	protected $config = [
		"form" => [
			"admin" => ["type" => "boolean", "value" => false, "label" => "Create admin account"],
			"username" => ["text" => "admin"],
			"password" => "password",
			"email" => "text",
		],
		"database" => false,
		"resources" => [
			"composer" => ["src" => "getgrav/grav", "dst" => "/"],
		],
		"server" => [
			"nginx" => [
				"template" => "grav",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1". "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null) {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		if ($options["admin"] == true) {
			chdir($installationTarget->getDocRoot());

			$this->appcontext->runPHP(
				$options["php_version"],
				$installationTarget->getDocRoot("/bin/gpm"),
				["install admin"],
			);

			$this->appcontext->runPHP(
				$options["php_version"],
				$installationTarget->getDocRoot("/bin/plugin"),
				[
					"login new-user",
					"-u " . $options["username"],
					"-p " . $options["password"],
					"-e " . $options["email"],
					"-P a",
					"-N " . $options["username"],
					"-l en",
				],
			);
		}

		return true;
	}
}
