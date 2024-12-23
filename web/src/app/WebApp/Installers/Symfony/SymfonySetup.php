<?php

namespace Hestia\WebApp\Installers\Symfony;

use Hestia\WebApp\Installers\BaseSetup;

class SymfonySetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Symfony",
		"group" => "framework",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "symfony-thumb.png",
	];

	protected $config = [
		"form" => [],
		"database" => true,
		"resources" => [
			"composer" => ["src" => "symfony/website-skeleton", "dst" => "/"],
		],
		"server" => [
			"nginx" => [
				"template" => "symfony4-5",
			],
			"php" => [
				"supported" => ["8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);

		$installationTarget = $this->getInstallationTarget();

		$result = null;

		$htaccess_rewrite = '
<IfModule mod_rewrite.c>
		RewriteEngine On
		RewriteRule ^(.*)$ public/$1 [L]
</IfModule>';

		$this->appcontext->runComposer(
			["config", "-d " . $installationTarget->getDocRoot(), "extra.symfony.allow-contrib", "true"],
			$result,
		);
		$this->appcontext->runComposer(
			["require", "-d " . $installationTarget->getDocRoot(), "symfony/apache-pack"],
			$result,
		);

		$tmp_configpath = $this->saveTempFile($htaccess_rewrite);
		$this->appcontext->runUser(
			"v-move-fs-file",
			[$tmp_configpath, $installationTarget->getDocRoot(".htaccess")],
			$result,
		);

		return $result->code === 0;
	}
}
