<?php

namespace Hestia\WebApp\Installers\NamelessMC;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;

class NamelessMCSetup extends BaseSetup {
	protected $appInfo = [
		"name" => "NamelessMC",
		"group" => "cms",
		"enabled" => true,
		"version" => "2.1.2",
		"thumbnail" => "namelessmc.png",
	];

	protected $config = [
		"form" => [
			"protocol" => [
				"type" => "select",
				"options" => ["http", "https"],
				"value" => "https",
			],
		],
		"database" => false,
		"resources" => [
			"archive" => [
				"src" =>
					"https://github.com/NamelessMC/Nameless/releases/download/v2.1.2/nameless-deps-dist.zip",
			],
		],
		"server" => [
			"nginx" => [
				"template" => "namelessmc",
			],
			"apache2" => [
				"template" => "namelessmc",
			],
			"php" => [
				"supported" => ["7.4", "8.0", "8.1"],
			],
		],
	];

	public function install(array $options = null) {
		parent::install($options);

		$status = 0;

		return $status === 0;
	}
}
