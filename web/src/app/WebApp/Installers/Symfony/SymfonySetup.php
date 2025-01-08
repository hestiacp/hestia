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
			"apache2" => [
				"document_root" => "public",
			],
			"nginx" => [
				"template" => "symfony4-5",
			],
			"php" => [
				"supported" => ["8.2", "8.3"],
			],
		],
	];

	public function install(array $options = null): void {
		parent::install($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->runComposer(
			$options["php_version"],
			[
				"config",
				"-d",
				$installationTarget->getDocRoot(),
				"extra.symfony.allow-contrib",
				"true",
			],
		);
		$this->appcontext->runComposer(
			$options["php_version"],
			[
				"require",
				"-d",
				$installationTarget->getDocRoot(),
				"symfony/apache-pack",
			],
		);
	}
}
