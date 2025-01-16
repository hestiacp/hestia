<?php
use function Hestiacp\quoteshellarg\quoteshellarg;

ob_start();
$TAB = "WEB";

// Main include
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

// Check POST request
if (!empty($_POST["ok"])) {
	// Check token
	verify_csrf($_POST);

	// Check for empty fields
	if (empty($_POST["v_domain"])) {
		$errors[] = _("Domain");
	}
	if (empty($_POST["v_ip"])) {
		$errors[] = _("IP Address");
	}

	if (!empty($errors[0])) {
		foreach ($errors as $i => $error) {
			if ($i == 0) {
				$error_msg = $error;
			} else {
				$error_msg = $error_msg . ", " . $error;
			}
		}
		$_SESSION["error_msg"] = sprintf(_('Field "%s" can not be blank.'), $error_msg);
	}

	// Set domain to lowercase and remove www prefix
	$v_domain = preg_replace("/^www\./i", "", $_POST["v_domain"]);
	$v_domain = strtolower($v_domain);

	// Define domain ip address
	$v_ip = quoteshellarg($_POST["v_ip"]);

	// Using public IP instead of internal IP when creating DNS
	// Gets public IP from 'v-list-user-ips' command (that reads /hestia/data/ips/ip), precisely from 'NAT' field
	$v_public_ip = $v_ip;
	$v_clean_ip = $_POST["v_ip"]; // clean_ip = IP without quotas
	exec(HESTIA_CMD . "v-list-user-ips " . $user . " json", $output, $return_var);
	$ips = json_decode(implode("", $output), true);
	unset($output);
	if (
		isset($ips[$v_clean_ip]) &&
		isset($ips[$v_clean_ip]["NAT"]) &&
		trim($ips[$v_clean_ip]["NAT"]) != ""
	) {
		$v_public_ip = trim($ips[$v_clean_ip]["NAT"]);
		$v_public_ip = quoteshellarg($v_public_ip);
	}

	// Define domain aliases
	$v_aliases = "";

	// Define proxy extensions
	$_POST["v_proxy_ext"] = "";
	$_POST["v_proxy_url"] = "";

	exec(HESTIA_CMD . "v-list-user " . $user . " json", $output, $return_var);
	$user_config = json_decode(implode("", $output), true);
	unset($output);

	$v_template = $user_config[$user_plain]["WEB_TEMPLATE"];
	$v_backend_template = $user_config[$user_plain]["BACKEND_TEMPLATE"];
	$v_proxy_template = $user_config[$user_plain]["PROXY_TEMPLATE"];

	// Add web domain
	if (empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD .
				"v-add-web-domain " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				$v_ip .
				" 'yes'",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$domain_added = empty($_SESSION["error_msg"]);
	}

	if (empty($_POST["v_dns"])) {
		$_POST["v_dns"] = "no";
	}
	if (empty($_POST["v_mail"])) {
		$_POST["v_mail"] = "no";
	}
	// Add DNS domain
	if ($_POST["v_dns"] == "on" && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD .
				"v-add-dns-domain " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				$v_public_ip .
				" '' '' '' '' '' '' '' '' 'no'",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Add mail domain
	if ($_POST["v_mail"] == "on" && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-add-mail-domain " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Flush field values on success
	if (empty($_SESSION["error_msg"])) {
		$_SESSION["ok_msg"] = htmlify_trans(
			sprintf(_("Domain {%s} has been created successfully."), htmlentities($v_domain)),
			"</a>",
			'<a href="/edit/web/?domain=' . htmlentities($v_domain) . '">',
		);
		unset($v_domain);
		unset($v_aliases);
	}
}
// Define user variables
$v_aliases = "";

// List user package
exec(HESTIA_CMD . "v-list-user " . $user . " json", $output, $return_var);
$user_config = json_decode(implode("", $output), true);
unset($output);
// List web templates and set default values
exec(HESTIA_CMD . "v-list-web-templates json", $output, $return_var);
$templates = json_decode(implode("", $output), true);
unset($output);
$v_template = !empty($_POST["v_template"])
	? $_POST["v_template"]
	: $user_config[$user_plain]["WEB_TEMPLATE"];
// List backend templates
if (!empty($_SESSION["WEB_BACKEND"])) {
	exec(HESTIA_CMD . "v-list-web-templates-backend json", $output, $return_var);
	$backend_templates = json_decode(implode("", $output), true);
	unset($output);
	$v_backend_template = !empty($_POST["v_backend_template"])
		? $_POST["v_backend_template"]
		: $user_config[$user_plain]["BACKEND_TEMPLATE"];
}

// List proxy templates
if (!empty($_SESSION["PROXY_SYSTEM"])) {
	exec(HESTIA_CMD . "v-list-web-templates-proxy json", $output, $return_var);
	$proxy_templates = json_decode(implode("", $output), true);
	unset($output);
	$v_proxy_template = !empty($_POST["v_proxy_template"])
		? $_POST["v_proxy_template"]
		: $user_config[$user_plain]["PROXY_TEMPLATE"];
}

// List IP addresses
exec(HESTIA_CMD . "v-list-user-ips " . $user . " json", $output, $return_var);
$ips = json_decode(implode("", $output), true);
unset($output);

// Get all user domains
exec(HESTIA_CMD . "v-list-web-domains " . $user . " json", $output, $return_var);
$user_domains = json_decode(implode("", $output), true);
$user_domains = array_keys($user_domains);
unset($output);

$accept = $_GET["accept"] ?? "";

$v_domain = $_POST["domain"] ?? "";

// Render page
render_page($user, $TAB, "add_web");

// Flush session messages
unset($_SESSION["error_msg"]);
unset($_SESSION["ok_msg"]);
