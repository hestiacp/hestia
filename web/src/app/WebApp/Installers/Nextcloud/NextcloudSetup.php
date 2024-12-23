<?php

namespace Hestia\WebApp\Installers\Nextcloud;

use Hestia\WebApp\Installers\BaseSetup;
use function Hestiacp\quoteshellarg\quoteshellarg;

class NextcloudSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Nextcloud",
		"group" => "cloud",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "nextcloud-thumb.png",
	];

	protected $config = [
		"form" => [
			"username" => ["value" => "admin"],
			"password" => "password",
		],
		"database" => true,
		"resources" => [
			"archive" => ["src" => "https://download.nextcloud.com/server/releases/latest.tar.bz2"],
		],
		"server" => [
			"nginx" => [
				"template" => "owncloud",
			],
			"php" => [
				"supported" => ["8.0", "8.1", "8.2"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				quoteshellarg($installationTarget->getDocRoot("occ")),
				"maintenance:install",
				"--database mysql",
				"--database-name " .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_name"]),
				"--database-host " . quoteshellarg($options["database_host"]),
				"--database-user " .
				quoteshellarg($this->appcontext->user() . "_" . $options["database_user"]),
				"--database-pass " . quoteshellarg($options["database_password"]),
				"--admin-user " . quoteshellarg($options["username"]),
				"--admin-pass " . quoteshellarg($options["password"]),
			],
			$status,
		);

		$this->appcontext->runUser(
			"v-run-cli-cmd",
			[
				"/usr/bin/php" . $options["php_version"],
				quoteshellarg($installationTarget->getDocRoot("occ")),
				"config:system:set",
				"trusted_domains 2 --value=" . quoteshellarg($installationTarget->domainName),
			],
			$status,
		);

		// Bump minimum memory limit to 512M
		$result = null;
		$file = $installationTarget->getDocRoot(".user.ini");
		$this->appcontext->runUser("v-open-fs-file", [$file], $result);
		array_push($result->raw, "memory_limit=512M");
		$tmp = $this->saveTempFile(implode("\r\n", $result->raw));
		if (!$this->appcontext->runUser("v-move-fs-file", [$tmp, $file], $result)) {
			throw new \Exception("Error updating file in: " . $tmp . " " . $result->text);
		}

		return $status->code === 0;
	}
}
