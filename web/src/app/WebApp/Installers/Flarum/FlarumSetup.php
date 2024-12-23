<?php
namespace Hestia\WebApp\Installers\Flarum;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

class FlarumSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Flarum",
		"group" => "forum",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "fl-thumb.png",
	];

	protected $config = [
		"form" => [
			"forum_title" => ["type" => "text", "value" => "Flarum Forum"],
			"admin_username" => ["value" => "fladmin"],
			"admin_email" => "text",
			"admin_password" => "password",
			"install_directory" => ["type" => "text", "value" => "", "placeholder" => "/"],
		],
		"database" => true,
		"resources" => [
			"composer" => ["src" => "flarum/flarum"],
		],
		"server" => [
			"nginx" => [
				"template" => "flarum",
			],
			"php" => [
				"supported" => ["8.0", "8.1", "8.2"],
			],
		],
	];

	// Our updateFile routine done the 'Hestia way'
	public function updateFile($file, $search, $replace) {
		$result = null;
		$this->appcontext->runUser("v-open-fs-file", [$file], $result);
		foreach ($result->raw as $line_num => $line) {
			if (strpos($line, $search) !== false) {
				$result->raw[$line_num] = str_replace($search, $replace, $line);
			}
		}
		$tmp = $this->saveTempFile(implode("\r\n", $result->raw));
		if (!$this->appcontext->runUser("v-move-fs-file", [$tmp, $file], $result)) {
			throw new \Exception("Error updating file in: " . $tmp . " " . $result->text);
		}
		return $result;
	}

	public function install(array $options = null): bool {
		parent::setInstallationDirectory($options["install_directory"]);
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$result = null;

		// Move public folder content (https://docs.flarum.org/install/#customizing-paths)
		if (
			!$this->appcontext->runUser(
				"v-list-fs-directory",
				[$installationTarget->getDocRoot("public")],
				$result,
			)
		) {
			throw new \Exception(
				"Error listing folder at: " . $installationTarget->getDocRoot("public") . $result->text,
			);
		}
		foreach ($result->raw as $line_num => $line) {
			$detail = explode("|", $line);
			$type = $detail[0];
			$name = end($detail);
			if ($name != "") {
				if ($type == "d") {
					// Directory
					if (
						!$this->appcontext->runUser(
							"v-move-fs-directory",
							[
								$installationTarget->getDocRoot("public") . "/" . $name,
								$installationTarget->getDocRoot() . "/" . $name,
							],
							$result,
						)
					) {
						throw new \Exception(
							"Error moving folder at: " .
								$installationTarget->getDocRoot("public") .
								"/" .
								$name .
								$result->text,
						);
					}
				} else {
					if (
						!$this->appcontext->runUser(
							"v-move-fs-file",
							[
								$installationTarget->getDocRoot("public") . "/" . $name,
								$installationTarget->getDocRoot() . "/" . $name,
							],
							$result,
						)
					) {
						throw new \Exception(
							"Error moving file at: " .
								$installationTarget->getDocRoot("public") .
								"/" .
								$name .
								$result->text,
						);
					}
				}
			}
		}
		if (
			!$this->appcontext->runUser(
				"v-delete-fs-directory",
				[$installationTarget->getDocRoot("public")],
				$result,
			)
		) {
			throw new \Exception(
				"Error deleting folder at: " . $installationTarget->getDocRoot("public") . $result->text,
			);
		}

		// Not using 'public'; enable protection rewrite rules and update paths
		$result = $this->updateFile(
			$installationTarget->getDocRoot(".htaccess"),
			"# RewriteRule ",
			"RewriteRule ",
		);
		$result = $this->updateFile(
			$installationTarget->getDocRoot("index.php"),
			'$site = require \'../site.php\';',
			'$site = require \'./site.php\';',
		);
		$result = $this->updateFile(
			$installationTarget->getDocRoot("site.php"),
			"'public' => __DIR__.'/public',",
			"'public' => __DIR__,",
		);

		$mysql_host = $options["database_host"];
		$mysql_database = addcslashes(
			$this->appcontext->user() . "_" . $options["database_name"],
			"\\'",
		);
		$mysql_username = addcslashes(
			$this->appcontext->user() . "_" . $options["database_user"],
			"\\'",
		);
		$mysql_password = addcslashes($options["database_password"], "\\'");
		$table_prefix = addcslashes(Util::generate_string(5, false) . "_", "\\'");
		$subfolder = $options["install_directory"];
		if (substr($subfolder, 0, 1) != "/") {
			$subfolder = "/" . $subfolder;
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
			quoteshellarg($installationTarget->getUrl() . '/' . $subfolder . "/index.php"),
			"--data-binary " .
			quoteshellarg(
				http_build_query([
					"forumTitle" => $options["forum_title"],
					"mysqlHost" => $mysql_host,
					"mysqlDatabase" => $mysql_database,
					"mysqlUsername" => $mysql_username,
					"mysqlPassword" => $mysql_password,
					"tablePrefix" => $table_prefix,
					"adminUsername" => $options["admin_username"],
					"adminEmail" => $options["admin_email"],
					"adminPassword" => $options["admin_password"],
					"adminPasswordConfirmation" => $options["admin_password"],
				]),
			),
		]);
		exec($cmd, $output, $return_var);

		// Report any errors
		if ($return_var > 0) {
			throw new \Exception(implode(PHP_EOL, $output));
		}
		return $result->code === 0 && $return_var === 0;
	}
}
