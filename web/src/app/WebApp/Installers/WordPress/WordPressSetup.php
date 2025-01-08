<?php

namespace Hestia\WebApp\Installers\WordPress;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;
use function file_get_contents;
use function var_export;

class WordPressSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "WordPress",
		"group" => "cms",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "wp-thumb.png",
	];

	protected $config = [
		"form" => [
			"site_name" => ["type" => "text", "value" => "WordPress Blog"],
			"username" => ["value" => "wpadmin"],
			"email" => "text",
			"password" => "password",
			"install_directory" => ["type" => "text", "value" => "/", "placeholder" => "/"],
			"language" => [
				"type" => "select",
				"value" => "en_US",
				"options" => [
					"cs_CZ" => "Czech",
					"de_DE" => "German",
					"es_ES" => "Spanish",
					"en_US" => "English",
					"fr_FR" => "French",
					"hu_HU" => "Hungarian",
					"it_IT" => "Italian",
					"ja" => "Japanese",
					"nl_NL" => "Dutch",
					"pt_PT" => "Portuguese",
					"pt_BR" => "Portuguese (Brazil)",
					"sk_SK" => "Slovak",
					"sr_RS" => "Serbian",
					"sv_SE" => "Swedish",
					"tr_TR" => "Turkish",
					"ru_RU" => "Russian",
					"uk" => "Ukrainian",
					"zh-CN" => "Simplified Chinese (China)",
					"zh_TW" => "Traditional Chinese",
				],
			],
		],
		"database" => true,
		"resources" => [
			"wp" => ["src" => "https://wordpress.org/latest.tar.gz"],
		],
		"server" => [
			"nginx" => [
				"template" => "wordpress",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1", "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::setInstallationDirectory($options["install_directory"]);
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runWp(
			$options["php_version"],
			[
				"config",
				"create",
				"--dbname=" . $this->appcontext->user() . "_" . $options["database_name"],
				"--dbuser=" . $this->appcontext->user() . "_" . $options["database_user"],
				"--dbpass=" . $options["database_password"],
				"--dbhost=" . $options["database_host"],
				"--dbprefix=" . "wp_" . Util::generate_string(5, false) . '_',
				"--dbcharset=utf8mb4",
				"--locale=" . $options["language"],
				"--path=" . $installationTarget->getDocRoot(),
			],
		);

		$wpPasswordBcryptContents = file_get_contents(
			'https://raw.githubusercontent.com/roots/wp-password-bcrypt/master/wp-password-bcrypt.php',
		);

		$this->appcontext->addDirectory(
			$installationTarget->getDocRoot("wp-content/mu-plugins/"),
		);

		$this->appcontext->createFile(
			$installationTarget->getDocRoot("wp-content/mu-plugins/wp-password-bcrypt.php"),
			$wpPasswordBcryptContents,
		);

		// WordPress CLI seems to have a bug that when site name has a space it will be seen as an
		// extra argument. Even when properly escaped. For now just install with install.php
		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl() . '/' . $options["install_directory"] . "/wp-admin/install.php?step=2",
			[
				"weblog_title" => $options["site_name"],
				"user_name" => $options["username"],
				"admin_password" => $options["password"],
				"admin_password2" => $options["password"],
				"admin_email" => $options["email"],
			]
		);
	}
}
