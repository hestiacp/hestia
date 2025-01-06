<?php

namespace Hestia\WebApp\Installers\MediaWiki;

use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

class MediaWikiSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "MediaWiki",
		"group" => "cms",
		"enabled" => true,
		"version" => "1.42.3",
		"thumbnail" => "MediaWiki-2020-logo.svg", //Max size is 300px by 300px
	];

	protected $extractsubdir = "/tmp-mediawiki";

	protected $config = [
		"form" => [
			"admin_username" => ["type" => "text", "value" => "admin"],
			"admin_password" => "password",
			"language" => ["type" => "text", "value" => "en"],
		],
		"database" => true,
		"resources" => [
			"archive" => [
				"src" => "https://releases.wikimedia.org/mediawiki/1.42/mediawiki-1.42.3.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "default",
			],
			"php" => [
				"supported" => ["8.0", "8.1", "8.2"],
			],
		],
	];

	public function install(array $options = null) {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runUser(
			"v-copy-fs-directory",
			[$installationTarget->getDocRoot($this->extractsubdir . "/mediawiki-1.42.3/."), $installationTarget->getDocRoot()],
			$result,
		);

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				quoteshellarg($installationTarget->getDocRoot("maintenance/install.php")),
				"--dbserver=" . quoteshellarg($options["database_host"]),
				"--dbname=" .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_name"]),
				"--installdbuser=" .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_user"]),
				"--installdbpass=" . quoteshellarg($options["database_password"]),
				"--dbuser=" .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_user"]),
				"--dbpass=" . quoteshellarg($options["database_password"]),
				"--server=" . quoteshellarg($installationTarget->getUrl()),
				"--scriptpath=", // must NOT be /
				"--lang=" . quoteshellarg($options["language"]),
				"--pass=" . quoteshellarg($options["admin_password"]),
				"MediaWiki", // A Space here would trigger the next argument and preemptively set the admin username
				quoteshellarg($options["admin_username"]),
			],
			$status,
		);

		$this->cleanup();

		return $status->code === 0;
	}
}
