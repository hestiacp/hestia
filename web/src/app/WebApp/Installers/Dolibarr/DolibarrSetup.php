<?php

namespace Hestia\WebApp\Installers\Dolibarr;

use Hestia\WebApp\Installers\BaseSetup;

class DolibarrSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Dolibarr",
		"group" => "CRM",
		"enabled" => true,
		"version" => "20.0.2",
		"thumbnail" => "dolibarr-thumb.png",
	];

	protected $config = [
		"form" => [
			"dolibarr_account_username" => ["value" => "admin"],
			"dolibarr_account_password" => "password",
			"language" => [
				"type" => "select",
				"options" => [
					"en_EN" => "English",
					"es_ES" => "Spanish",
					"fr_FR" => "French",
					"de_DE" => "German",
					"pt_PT" => "Portuguese",
					"it_IT" => "Italian",
				],
				"default" => "en_EN",
			],
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" => "https://github.com/Dolibarr/dolibarr/archive/refs/tags/20.0.2.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "dolibarr",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1", "8.2", "8.3"],
			],
			"document_root" => "htdocs",
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->copyDirectory(
			$installationTarget->getDocRoot("/dolibarr-" . $this->appInfo["version"] . "/."),
			$installationTarget->getDocRoot()
		);

		$language = $options["language"] ?? "en_EN";

		$this->appcontext->moveFile(
			$installationTarget->getDocRoot("htdocs/conf/conf.php.example"),
			$installationTarget->getDocRoot("htdocs/conf/conf.php"),
		);

		$this->appcontext->changeFilePermissions(
			$installationTarget->getDocRoot("htdocs/conf/conf.php"),
			"666"
		);

		$this->appcontext->addDirectory($installationTarget->getDocRoot("documents"));

		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl() . "/install/step1.php",
			[
				'testpost' => 'ok',
				'action' => 'set',
				'main_dir' => $installationTarget->getDocRoot("htdocs"),
				'main_data_dir' => $installationTarget->getDocRoot("documents"),
				'main_url' => $installationTarget->getUrl(),
				'db_type' => 'mysqli',
				'db_host' => 'localhost',
				'db_port' => '3306',
				'db_prefix' => 'llx_',
				'db_name' => $this->appcontext->user() . "_" . $options["database_name"],
				'db_user' => $this->appcontext->user() . "_" . $options["database_user"],
				'db_pass' => $options["database_password"],
				'selectlang' => $language,
			]
		);

		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl() . "/install/step2.php",
			[
				'testpost' => 'ok',
				'action' => 'set',
				'dolibarr_main_db_character_set' => 'utf8',
				'dolibarr_main_db_collation' => 'utf8_unicode_ci',
				'selectlang' => $language,
			]
		);

		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl() . "/install/step4.php",
			[
				'testpost' => 'ok',
				'action' => 'set',
				'dolibarrpingno' => 'checked',
				'selectlang' => $language,
			]
		);

		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl() . "/install/step5.php",
			[
				'testpost' => 'ok',
				'login' => $options["dolibarr_account_username"],
				'pass' => $options["dolibarr_account_password"],
				'selectlang' => $language,
			]
		);

		$this->cleanup();

		return true;
	}
}
