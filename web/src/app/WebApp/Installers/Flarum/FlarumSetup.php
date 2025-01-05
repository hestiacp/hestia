<?php
namespace Hestia\WebApp\Installers\Flarum;

use Hestia\System\Util;
use Hestia\WebApp\Installers\BaseSetup;

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
				"supported" => ["8.2", "8.3"],
			],
			"document_root" => "public",
		],
	];

	public function install(array $options = null): bool {
		parent::install($options);
		parent::setup($options);

		$installationTarget = $this->getInstallationTarget();

		$this->appcontext->sendPostRequest(
			$installationTarget->getUrl(),
			[
				"forumTitle" => $options["forum_title"],
				"mysqlHost" => $options["database_host"],
				"mysqlDatabase" => $this->appcontext->user() . "_" . $options["database_name"],
				"mysqlUsername" => $this->appcontext->user() . "_" . $options["database_user"],
				"mysqlPassword" => $options["database_password"],
				"tablePrefix" => 'fl' . Util::generate_string(5, false),
				"adminUsername" => $options["admin_username"],
				"adminEmail" => $options["admin_email"],
				"adminPassword" => $options["admin_password"],
				"adminPasswordConfirmation" => $options["admin_password"],
			],
		);

		return true;
	}
}
