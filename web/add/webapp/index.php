<?php
use function Hestiacp\quoteshellarg\quoteshellarg;

ob_start();
$TAB = "WEB";

// Main include
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";
require_once $_SERVER["DOCUMENT_ROOT"] . "/src/init.php";

// Check domain argument
if (empty($_GET["domain"])) {
	header("Location: /list/web/");
	exit();
}

// Edit as someone else?
if ($_SESSION["user"] == "admin" && !empty($_GET["user"])) {
	$user = quoteshellarg($_GET["user"]);
}

// Check if domain belongs to the user
$v_domain = $_GET["domain"];
exec(
	HESTIA_CMD . "v-list-web-domain " . $user . " " . quoteshellarg($v_domain) . " json",
	$output,
	$return_var,
);
if ($return_var > 0) {
	check_return_code_redirect($return_var, $output, "/list/web/");
}
unset($output);
exec(HESTIA_CMD . "v-list-sys-php json", $output, $return_var);
$php_versions = json_decode(implode("", $output), true);
unset($output);

// Check GET request
if (!empty($_GET["app"])) {
	$app = basename($_GET["app"]);

	$hestia = new \Hestia\System\HestiaApp();
	$app_installer_class = "\Hestia\WebApp\Installers\\" . $app . "\\" . $app . "Setup";
	if (class_exists($app_installer_class)) {
		try {
			$app_installer = new $app_installer_class($v_domain, $hestia);
			$info = $app_installer->info();
			foreach ($php_versions as $version) {
				if (in_array($version, $info["php_support"])) {
					$supported = true;
					$supported_versions[] = $version;
				}
			}
			if ($supported) {
				$info["enabled"] = true;
			} else {
				$info["enabled"] = false;
				$_SESSION["error_msg"] = sprintf(
					_("Unable to install %s, %s is not available."),
					$app,
					"PHP-" . end($info["php_support"]),
				);
			}
			if ($info["enabled"] == true) {
				$installer = new \Hestia\WebApp\AppWizard($app_installer, $v_domain, $hestia);
				$GLOBALS["WebappInstaller"] = $installer;
			}
		} catch (Exception $e) {
			$_SESSION["error_msg"] = $e->getMessage();
			header("Location: /add/webapp/?domain=" . $v_domain);
			exit();
		}
	} else {
		$_SESSION["error_msg"] = sprintf(_("%s installer missing."), $app);
	}
}

// Check POST request
if (!empty($_POST["ok"]) && !empty($app)) {
	// Check token
	verify_csrf($_POST);

	if ($installer) {
		try {
			$installer->execute($_POST);

			$_SESSION["ok_msg"] = sprintf(_("%s installed successfully."), htmlspecialchars($app));

			header("Location: /add/webapp/?domain=" . $v_domain);
			exit();
		} catch (Exception $e) {
			$_SESSION["error_msg"] = $e->getMessage();
			header("Location: /add/webapp/?app=" . rawurlencode($app) . "&domain=" . $v_domain);
			exit();
		}
	}
}

if (!empty($installer)) {
	render_page($user, $TAB, "setup_webapp");
} else {
	$appInstallers = glob(__DIR__ . "/../../src/app/WebApp/Installers/*/*.php");
	$v_web_apps = [];
	foreach ($appInstallers as $app) {
		$hestia = new \Hestia\System\HestiaApp();
		if (
			preg_match(
				"/Installers\/([a-zA-Z][a-zA-Z0,9].*)\/([a-zA-Z][a-zA-Z0,9].*).php/",
				$app,
				$matches,
			)
		) {
			if ($matches[1] != "Resources") {
				$app_installer_class =
					"\Hestia\WebApp\Installers\\" . $matches[1] . "\\" . $matches[1] . "Setup";
				$app_installer = new $app_installer_class($v_domain, $hestia);
				$appInstallerInfo = $app_installer->info();
				$supported = false;
				$supported_versions = [];
				foreach ($php_versions as $version) {
					if (in_array($version, $appInstallerInfo["php_support"])) {
						$supported = true;
						$supported_versions[] = $version;
					}
				}
				if ($supported) {
					$appInstallerInfo["enabled"] = true;
				} else {
					$appInstallerInfo["enabled"] = false;
				}
				$v_web_apps[] = $appInstallerInfo;
			}
		}
	}
	render_page($user, $TAB, "list_webapps");
}

// Flush session messages
unset($_SESSION["error_msg"]);
unset($_SESSION["ok_msg"]);
