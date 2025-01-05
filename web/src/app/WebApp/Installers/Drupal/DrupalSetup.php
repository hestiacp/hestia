<?php

namespace Hestia\WebApp\Installers\Drupal;

use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

class DrupalSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Drupal",
		"group" => "cms",
		"enabled" => "yes",
		"version" => "latest",
		"thumbnail" => "drupal-thumb.png",
	];

	protected $config = [
		"form" => [
			"username" => ["type" => "text", "value" => "admin"],
			"password" => "password",
			"email" => "text",
		],
		"database" => true,
		"resources" => [
			"composer" => ["src" => "drupal/recommended-project", "dst" => "/"],
		],
		"server" => [
			"nginx" => [
				"template" => "drupal-composer",
			],
			"php" => [
				"supported" => ["8.1", "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runComposer(
			["require", "-d " . $installationTarget->getDocRoot(), "drush/drush"],
			$status2,
			["version" => 2, "php_version" => $options["php_version"]],
		);

		$htaccessContents = '
<IfModule mod_rewrite.c>
		RewriteEngine On
		RewriteRule ^(.*)$ web/$1 [L]
</IfModule>';

		$this->appcontext->createFile(
			$installationTarget->getDocRoot(".htaccess"),
			$htaccessContents,
		);

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				quoteshellarg($installationTarget->getDocRoot("/vendor/drush/drush/drush")),
				"site-install",
				"standard",
				"--db-url=" .
				quoteshellarg(
					"mysql://" .
						$this->appcontext->user() .
						"_" .
						$options["database_user"] .
						":" .
						$options["database_password"] .
						"@" .
						$options["database_host"] .
						":3306/" .
						$this->appcontext->user() .
						"_" .
						$options["database_name"],
				),
				"--account-name=" . quoteshellarg($options["username"]),
				"--account-pass=" . quoteshellarg($options["password"]),
				"--site-name=Drupal",
				"--site-mail=" . quoteshellarg($options["email"]),
			],
			$status,
		);
		return $status->code === 0;
	}
}
