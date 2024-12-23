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
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runUser(
			"v-copy-fs-directory",
			[
				$installationTarget->getDocRoot($this->extractsubdir . "/dolibarr-20.0.2/."),
				$installationTarget->getDocRoot()
			],
			$status,
		);

		$language = $options["language"] ?? "en_EN";
		$username = rawurlencode($options["dolibarr_account_username"]);
		$password = rawurlencode($options["dolibarr_account_password"]);
		$databaseUser = rawurlencode($this->appcontext->user() . "_" . $options["database_user"]);
		$databasePassword = rawurlencode($options["database_password"]);
		$databaseName = rawurlencode($this->appcontext->user() . "_" . $options["database_name"]);

		$this->appcontext->runUser(
			"v-copy-fs-file",
			[
				$installationTarget->getDocRoot("htdocs/conf/conf.php.example"),
				$installationTarget->getDocRoot("htdocs/conf/conf.php"),
			],
			$status,
		);

		$this->appcontext->runUser(
			"v-change-fs-file-permission",
			[$installationTarget->getDocRoot("htdocs/conf/conf.php"), "666"],
			$status,
		);

		$cmd =
			"curl --request POST " .
			($installationTarget->isSslEnabled ? "" : "--insecure ") .
			"--url " . $installationTarget->getUrl() . "/install/step1.php " .
			"--data 'testpost=ok&action=set" .
			"&main_dir=" .
			rawurlencode($installationTarget->getDocRoot("htdocs")) .
			"&main_data_dir=" .
			rawurlencode($installationTarget->getDocRoot("documents")) .
			"&main_url=" .
			rawurlencode($installationTarget->getUrl()) .
			"&db_name=$databaseName" .
			"&db_type=mysqli" .
			"&db_host=localhost" .
			"&db_port=3306" .
			"&db_prefix=llx_" .
			"&db_user=$databaseUser" .
			"&db_pass=$databasePassword" .
			"&selectlang=$language' && " .
			"curl --request POST " .
			($installationTarget->isSslEnabled ? "" : "--insecure ") .
			"--url " . $installationTarget->getUrl() . "/install/step2.php " .
			"--data 'testpost=ok&action=set" .
			"&dolibarr_main_db_character_set=utf8" .
			"&dolibarr_main_db_collation=utf8_unicode_ci" .
			"&selectlang=$language' && " .
			"curl --request POST " .
			($installationTarget->isSslEnabled ? "" : "--insecure ") .
			"--url " . $installationTarget->getUrl() . "/install/step4.php " .
			"--data 'testpost=ok&action=set" .
			"&dolibarrpingno=checked" .
			"&selectlang=$language' && " .
			"curl --request POST " .
			($installationTarget->isSslEnabled ? "" : "--insecure ") .
			"--url " . $installationTarget->getUrl() . "/install/step5.php " .
			"--data 'testpost=ok&action=set" .
			"&login=$username" .
			"&pass=$password" .
			"&pass_verif=$password" .
			"&selectlang=$language'";

		exec($cmd, $output, $return_var);
		if ($return_var > 0) {
			throw new \Exception(implode(PHP_EOL, $output));
		}

		$this->cleanup();

		return $status->code === 0;
	}
}
