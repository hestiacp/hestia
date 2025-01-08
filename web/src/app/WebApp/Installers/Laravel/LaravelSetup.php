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
		"database" => false,
		"resources" => [
			"composer" => ["src" => "laravel/laravel", "dst" => "/"],
		],
		"server" => [
			"apache2" => [
				"document_root" => "public",
			],
			"nginx" => [
				"template" => "laravel",
			],
			"php" => [
				"supported" => ["8.1", "8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::install($options);
		parent::setup($options);
	}
}
