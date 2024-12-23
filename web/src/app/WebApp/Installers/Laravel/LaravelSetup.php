<?php

namespace Hestia\WebApp\Installers\Laravel;

use Hestia\WebApp\Installers\BaseSetup;

class LaravelSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "Laravel",
		"group" => "framework",
		"enabled" => true,
		"version" => "latest",
		"thumbnail" => "laravel-thumb.png",
	];

	protected $config = [
		"form" => [],
		"database" => true,
		"resources" => [
			"composer" => ["src" => "laravel/laravel", "dst" => "/"],
		],
		"server" => [
			"nginx" => [
				"template" => "laravel",
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

		$result = null;

		$htaccess_rewrite = '
<IfModule mod_rewrite.c>
		RewriteEngine On
		RewriteRule ^(.*)$ public/$1 [L]
</IfModule>';

		$tmp_configpath = $this->saveTempFile($htaccess_rewrite);
		$this->appcontext->runUser(
			"v-move-fs-file",
			[$tmp_configpath, $installationTarget->getDocRoot(".htaccess")],
			$result,
		);

		return $result->code === 0;
	}
}
