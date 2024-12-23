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
			"thirtybees_account_first_name" => ["value" => "John"],
			"thirtybees_account_last_name" => ["value" => "Doe"],
			"thirtybees_account_email" => "text",
			"thirtybees_account_password" => "password",
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" =>
					"https://github.com/thirtybees/thirtybees/releases/download/1.5.1/thirtybees-v1.5.1-php7.4.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "prestashop",
			],
			"php" => [
				"supported" => ["7.4", "8.0"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		try {
			$this->retrieveResources($options);
		} catch (\Exception $e) {
			// Registrar el error pero continuar con la instalación
			error_log("Error durante la descarga o extracción: " . $e->getMessage());
		}

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				$installationTarget->getDocRoot("/install/index_cli.php"),
				"--db_user=" . $this->appcontext->user() . "_" . $options["database_user"],
				"--db_password=" . $options["database_password"],
				"--db_name=" . $this->appcontext->user() . "_" . $options["database_name"],
				"--firstname=" . $options["thirtybees_account_first_name"],
				"--lastname=" . $options["thirtybees_account_last_name"],
				"--password=" . $options["thirtybees_account_password"],
				"--email=" . $options["thirtybees_account_email"],
				"--domain=" . $installationTarget->domainName,
				"--ssl=" . $installationTarget->isSslEnabled,
			],
			$status,
		);

		// Delete install directory
		$installDir = $installationTarget->getDocRoot("/install");
		if (is_dir($installDir)) {
			$this->appcontext->runUser("v-delete-fs-directory", [$installDir]);
		} else {
			error_log(
				"No se pudo encontrar el directorio de instalación para eliminar: " . $installDir,
			);
		}

		return $status->code === 0;
	}
}
