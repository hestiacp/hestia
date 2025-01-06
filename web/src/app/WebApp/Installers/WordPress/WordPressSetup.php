<?php

namespace Hestia\WebApp\Installers\WordPress;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

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
			//'protocol' => [
			//  'type' => 'select',
			//  'options' => ['http','https'],
			//],

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

	public function install(array $options = null) {
		parent::setInstallationDirectory($options["install_directory"]);
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runUser(
			"v-open-fs-file",
			[$installationTarget->getDocRoot("wp-config-sample.php")],
			$result,
		);

		$this->appcontext->runWp(
			[
				"core",
				"install",
				"--locale=" . $options["language"],
				"--version=" . $appinfo["version"],
				"--path=" . $destination,
			],
			$status,
		);

		foreach ($result->raw as $line_num => $line) {
			if (str_starts_with($line, '$table_prefix =')) {
				$result->raw[$line_num] = sprintf(
					"\$table_prefix = %s;\r\n",
					var_export("wp_" . Util::generate_string(5, false) . "_", true),
				);
				continue;
			}
			if (!preg_match('/^define\(\s*\'([A-Z_]+)\',([ ]+)/', $line, $match)) {
				continue;
			}
			$constant = $match[1];
			$padding = $match[2];
			switch ($constant) {
				case "DB_NAME":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export(
							$this->appcontext->user() . "_" . $options["database_name"],
							true,
						) .
						" );";
					break;
				case "DB_USER":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export(
							$this->appcontext->user() . "_" . $options["database_user"],
							true,
						) .
						" );";
					break;
				case "DB_PASSWORD":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export($options["database_password"], true) .
						" );";
					break;
				case "DB_HOST":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export($options["database_host"], true) .
						" );";
					break;
				case "DB_CHARSET":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export("utf8mb4", true) .
						" );";

					break;
				case "AUTH_KEY":
				case "SECURE_AUTH_KEY":
				case "LOGGED_IN_KEY":
				case "NONCE_KEY":
				case "AUTH_SALT":
				case "SECURE_AUTH_SALT":
				case "LOGGED_IN_SALT":
				case "NONCE_SALT":
					$result->raw[$line_num] =
						"define( " .
						var_export($constant, true) .
						"," .
						str_repeat(" ", strlen($padding)) .
						var_export(Util::generate_string(64), true) .
						" );";
					break;
			}
		}

		$tmp_configpath = $this->saveTempFile(implode("\r\n", $result->raw));

		if (
			!$this->appcontext->runUser(
				"v-move-fs-file",
				[$tmp_configpath, $installationTarget->getDocRoot("wp-config.php")],
				$result,
			)
		) {
			throw new \Exception(
				"Error installing config file in: " .
					$tmp_configpath .
					" to:" .
					$installationTarget->getDocRoot("wp-config.php") .
					$result->text,
			);
		}

		$this->appcontext->downloadUrl(
			"https://raw.githubusercontent.com/roots/wp-password-bcrypt/master/wp-password-bcrypt.php",
			null,
			$plugin_output,
		);
		$this->appcontext->runUser(
			"v-add-fs-directory",
			[$installationTarget->getDocRoot("wp-content/mu-plugins/")],
			$result,
		);
		if (
			!$this->appcontext->runUser(
				"v-copy-fs-file",
				[
					$plugin_output->file,
					$installationTarget->getDocRoot("wp-content/mu-plugins/wp-password-bcrypt.php"),
				],
				$result,
			)
		) {
			throw new \Exception(
				"Error installing wp-password-bcrypt file in: " .
					$plugin_output->file .
					" to:" .
					$installationTarget->getDocRoot("wp-content/mu-plugins/wp-password-bcrypt.php") .
					$result->text,
			);
		}

		if (substr($options["install_directory"], 0, 1) == "/") {
			$options["install_directory"] = substr($options["install_directory"], 1);
		}
		if (substr($options["install_directory"], -1, 1) == "/") {
			$options["install_directory"] = substr(
				$options["install_directory"],
				0,
				strlen($options["install_directory"]) - 1,
			);
		}
		$cmd = implode(" ", [
			"/usr/bin/curl",
			"--location",
			"--post301",
			"--insecure",
			"--resolve " .
			quoteshellarg(
				$installationTarget->domainName . ":" . $installationTarget->getPort() . ":" . $installationTarget->ipAddress,
			),
			quoteshellarg(
				$installationTarget->getUrl() . '/' . $options["install_directory"] . "/wp-admin/install.php?step=2",
			),
			"--data-binary " .
			quoteshellarg(
				http_build_query([
					"weblog_title" => $options["site_name"],
					"user_name" => $options["username"],
					"admin_password" => $options["password"],
					"admin_password2" => $options["password"],
					"admin_email" => $options["email"],
				]),
			),
		]);

		exec($cmd, $output, $return_var);

		if (
			strpos(implode(PHP_EOL, $output), "Error establishing a database connection") !== false
		) {
			throw new \Exception("Error establishing a database connection");
		}
		if ($return_var > 0) {
			throw new \Exception(implode(PHP_EOL, $output));
		}
		return $return_var === 0;
	}
}
