<?php
use function Hestiacp\quoteshellarg\quoteshellarg;

ob_start();
unset($_SESSION["error_msg"]);
$TAB = "WEB";

// Main include
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

// Check domain argument
if (empty($_GET["domain"])) {
	header("Location: /list/web/");
	exit();
}

// Edit as someone else?
if ($_SESSION["userContext"] === "admin" && !empty($_GET["user"])) {
	$user = quoteshellarg($_GET["user"]);
	$user_plain = htmlentities($_GET["user"]);
}

// Get all user domains
exec(HESTIA_CMD . "v-list-web-domains " . $user . " json", $output, $return_var);
$user_domains = json_decode(implode("", $output), true);
$user_domains = array_keys($user_domains);
unset($output);

$v_domain = $_GET["domain"];
exec(
	HESTIA_CMD . "v-list-web-domain " . $user . " " . quoteshellarg($v_domain) . " json",
	$output,
	$return_var,
);
# Check if domain exists if not return /list/web/
check_return_code_redirect($return_var, $output, "/list/web/");
$data = json_decode(implode("", $output), true);
unset($output);

// Parse domain
$v_ip = $data[$v_domain]["IP"];
$v_template = $data[$v_domain]["TPL"];
$v_aliases = str_replace(",", "\n", $data[$v_domain]["ALIAS"]);
$valiases = explode(",", $data[$v_domain]["ALIAS"]);

$v_ssl = $data[$v_domain]["SSL"];
if (!empty($v_ssl)) {
	exec(
		HESTIA_CMD . "v-list-web-domain-ssl " . $user . " " . quoteshellarg($v_domain) . " json",
		$output,
		$return_var,
	);
	$ssl_str = json_decode(implode("", $output), true);
	unset($output);
	$v_ssl_crt = $ssl_str[$v_domain]["CRT"];
	$v_ssl_key = $ssl_str[$v_domain]["KEY"];
	$v_ssl_ca = $ssl_str[$v_domain]["CA"];
	$v_ssl_subject = $ssl_str[$v_domain]["SUBJECT"];
	$v_ssl_aliases = $ssl_str[$v_domain]["ALIASES"];
	$v_ssl_not_before = $ssl_str[$v_domain]["NOT_BEFORE"];
	$v_ssl_not_after = $ssl_str[$v_domain]["NOT_AFTER"];
	$v_ssl_signature = $ssl_str[$v_domain]["SIGNATURE"];
	$v_ssl_pub_key = $ssl_str[$v_domain]["PUB_KEY"];
	$v_ssl_issuer = $ssl_str[$v_domain]["ISSUER"];
	$v_ssl_forcessl = $data[$v_domain]["SSL_FORCE"];
	$v_ssl_hsts = $data[$v_domain]["SSL_HSTS"];
}
$v_letsencrypt = $data[$v_domain]["LETSENCRYPT"];
if (empty($v_letsencrypt)) {
	$v_letsencrypt = "no";
}
$v_ssl_home = $data[$v_domain]["SSL_HOME"] ?? "";
$v_backend_template = $data[$v_domain]["BACKEND"] ?? "";
$v_nginx_cache = $data[$v_domain]["FASTCGI_CACHE"] ?? "";
$v_nginx_cache_duration = $data[$v_domain]["FASTCGI_DURATION"] ?? "";
$v_nginx_cache_check = "";
if (empty($v_nginx_cache_duration)) {
	$v_nginx_cache_duration = "2m";
	$v_nginx_cache_check = "";
} else {
	$v_nginx_cache_check = "on";
}
$v_proxy = $data[$v_domain]["PROXY"];
$v_proxy_template = $data[$v_domain]["PROXY"];
$v_proxy_url = $data[$v_domain]["PROXY_URL"];
$v_proxy_ext = str_replace(",", ", ", $data[$v_domain]["PROXY_EXT"]);
$v_stats = $data[$v_domain]["STATS"];
$v_stats_user = $data[$v_domain]["STATS_USER"];
$v_stats_password = "";

$v_custom_doc_root_prepath = "/home/" . $user_plain . "/web/";

$v_custom_doc_root = "";
$v_custom_doc_domain = "";
$v_custom_doc_folder = "";

if (!empty($data[$v_domain]["CUSTOM_DOCROOT"])) {
	$v_custom_doc_root = realpath($data[$v_domain]["CUSTOM_DOCROOT"]) . DIRECTORY_SEPARATOR;
}

if (
	!empty($v_custom_doc_root) &&
	false !==
		preg_match(
			"/\/home\/" . $user_plain . "\/web\/([[:alnum:]].*?)\/public_html\/([[:alnum:]].*)?/",
			$v_custom_doc_root,
			$matches,
		)
) {
	// Regex for extracting target web domain and custom document root. Regex test: https://regex101.com/r/2CLvIF/1

	if (!empty($matches[1])) {
		$v_custom_doc_domain = $matches[1];
	}

	if (!empty($matches[2])) {
		$v_custom_doc_folder = rtrim($matches[2], "/");
	}

	if ($v_custom_doc_domain && !in_array($v_custom_doc_domain, $user_domains)) {
		$v_custom_doc_domain = "";
		$v_custom_doc_folder = "";
	}
}

$redirect_code_options = [301, 302];
$v_redirect = $data[$v_domain]["REDIRECT"];
$v_redirect_code = $data[$v_domain]["REDIRECT_CODE"];
if (!in_array($v_redirect, ["www." . $v_domain, $v_domain])) {
	$v_redirect_custom = $v_redirect;
}

$v_ftp_user = $data[$v_domain]["FTP_USER"];
$v_ftp_path = $data[$v_domain]["FTP_PATH"];
if (!empty($v_ftp_user)) {
	$v_ftp_password = "";
}
if (isset($v_custom_doc_domain) && $v_custom_doc_domain != "") {
	$v_ftp_user_prepath = "/home/" . $user_plain . "/web/" . $v_custom_doc_domain;
} else {
	$v_ftp_user_prepath = "/home/" . $user_plain . "/web/" . $v_domain;
}

//$v_ftp_email = $panel[$user]['CONTACT'];
$v_ftp_email = "";
$v_suspended = $data[$v_domain]["SUSPENDED"];
if ($v_suspended == "yes") {
	$v_status = "suspended";
} else {
	$v_status = "active";
}
$v_time = $data[$v_domain]["TIME"];
$v_date = $data[$v_domain]["DATE"];

// List ip addresses
exec(HESTIA_CMD . "v-list-user-ips " . $user . " json", $output, $return_var);
$ips = json_decode(implode("", $output), true);
unset($output);

$v_ip_public = empty($ips[$v_ip]["NAT"]) ? $v_ip : $ips[$v_ip]["NAT"];

// List web templates
exec(HESTIA_CMD . "v-list-web-templates json", $output, $return_var);
$templates = json_decode(implode("", $output), true);
unset($output);

// List backend templates
if (!empty($_SESSION["WEB_BACKEND"])) {
	exec(HESTIA_CMD . "v-list-web-templates-backend json", $output, $return_var);
	$backend_templates = json_decode(implode("", $output), true);
	unset($output);
}

// List proxy templates
if (!empty($_SESSION["PROXY_SYSTEM"])) {
	exec(HESTIA_CMD . "v-list-web-templates-proxy json", $output, $return_var);
	$proxy_templates = json_decode(implode("", $output), true);
	unset($output);
}

// List web stat engines
exec(HESTIA_CMD . "v-list-web-stats json", $output, $return_var);
$stats = json_decode(implode("", $output), true);
unset($output);

// Check POST request
if (!empty($_POST["save"])) {
	$v_domain = $_POST["v_domain"];
	if (!in_array($v_domain, $user_domains)) {
		check_return_code(3, ["Unknown domain"]);
	}
	// Check token
	verify_csrf($_POST);

	// Change web domain IP
	$v_newip = "";
	$v_newip_public = "";

	if (!empty($_POST["v_ip"])) {
		$v_newip = $_POST["v_ip"];
		$v_newip_public = empty($ips[$v_newip]["NAT"]) ? $v_newip : $ips[$v_newip]["NAT"];
	}

	if ($v_ip != $_POST["v_ip"] && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD .
				"v-change-web-domain-ip " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				quoteshellarg($_POST["v_ip"]) .
				" 'no'",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		$restart_web = "yes";
		$restart_proxy = "yes";
		unset($output);
	}

	// Change dns domain IP
	if ($v_ip != $_POST["v_ip"] && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-list-dns-domain " . $user . " " . quoteshellarg($v_domain) . " json",
			$output,
			$return_var,
		);
		unset($output);
		if ($return_var == 0) {
			exec(
				HESTIA_CMD .
					"v-change-dns-domain-ip " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					quoteshellarg($v_newip_public) .
					" 'no'",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$restart_dns = "yes";
		}
	}

	// Change dns ip for each alias
	if ($v_ip != $_POST["v_ip"] && empty($_SESSION["error_msg"])) {
		foreach ($valiases as $v_alias) {
			exec(
				HESTIA_CMD . "v-list-dns-domain " . $user . " " . quoteshellarg($v_alias) . " json",
				$output,
				$return_var,
			);
			unset($output);
			if ($return_var == 0) {
				exec(
					HESTIA_CMD .
						"v-change-dns-domain-ip " .
						$user .
						" " .
						quoteshellarg($v_alias) .
						" " .
						quoteshellarg($v_newip_public),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
				$restart_dns = "yes";
			}
		}
	}

	// Change mail domain IP
	if ($v_ip != $_POST["v_ip"] && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-list-mail-domain " . $user . " " . quoteshellarg($v_domain) . " json",
			$output,
			$return_var,
		);
		unset($output);
		if ($return_var == 0) {
			exec(
				HESTIA_CMD . "v-rebuild-mail-domain " . $user . " " . quoteshellarg($v_domain),
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$restart_email = "yes";
		}
	}

	if (
		$_SESSION["POLICY_USER_EDIT_WEB_TEMPLATES"] == "yes" ||
		$_SESSION["userContext"] === "admin"
	) {
		// Change template
		if ($v_template != $_POST["v_template"] && empty($_SESSION["error_msg"])) {
			exec(
				HESTIA_CMD .
					"v-change-web-domain-tpl " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					quoteshellarg($_POST["v_template"]) .
					" 'no'",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$restart_web = "yes";
		}

		// Change backend template
		if (
			!empty($_SESSION["WEB_BACKEND"]) &&
			$v_backend_template != $_POST["v_backend_template"] &&
			empty($_SESSION["error_msg"])
		) {
			$v_backend_template = $_POST["v_backend_template"];
			exec(
				HESTIA_CMD .
					"v-change-web-domain-backend-tpl " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					quoteshellarg($v_backend_template),
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
		}

		// Enable/Disable nginx cache
		if (empty($_POST["v_nginx_cache_check"])) {
			$_POST["v_nginx_cache_check"] = "";
		}
		if (empty($v_nginx_cache_duration)) {
			$v_nginx_cache_duration = "";
		}
		if (
			($_SESSION["WEB_SYSTEM"] == "nginx" &&
				$v_nginx_cache_check != $_POST["v_nginx_cache_check"]) ||
			($v_nginx_cache_duration != $_POST["v_nginx_cache_duration"] &&
				($_POST["v_nginx_cache"] = "yes") &&
				empty($_SESSION["error_msg"]))
		) {
			if ($_POST["v_nginx_cache_check"] == "on") {
				if (empty($_POST["v_nginx_cache_duration"])) {
					$_POST["v_nginx_cache_duration"] = "2m";
				}
				exec(
					HESTIA_CMD .
						"v-add-fastcgi-cache " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($_POST["v_nginx_cache_duration"]),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
			} else {
				exec(
					HESTIA_CMD . "v-delete-fastcgi-cache " . $user . " " . quoteshellarg($v_domain),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
			}
			$restart_web = "yes";
		}

		// Delete proxy support
		if (
			!empty($_SESSION["PROXY_SYSTEM"]) &&
			!empty($v_proxy) &&
			empty($_POST["v_proxy"]) &&
			empty($_SESSION["error_msg"])
		) {
			exec(
				HESTIA_CMD .
					"v-delete-web-domain-proxy " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" 'no'",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			unset($v_proxy);
			$restart_web = "yes";
		}

		// Change proxy template / Update extension list
		if (
			!empty($_SESSION["PROXY_SYSTEM"]) &&
			!empty($v_proxy) &&
			!empty($_POST["v_proxy"]) &&
			empty($_SESSION["error_msg"])
		) {
			$ext = preg_replace("/\n/", " ", $_POST["v_proxy_ext"]);
			$ext = preg_replace("/,/", " ", $ext);
			$ext = preg_replace("/\s+/", " ", $ext);
			$ext = trim($ext);
			$ext = str_replace(" ", ", ", $ext);
			if ($v_proxy_template != $_POST["v_proxy_template"] || $v_proxy_ext != $ext || $v_proxy_url != $_POST["v_proxy_url"]) {
				$ext = str_replace(", ", ",", $ext);
				if (!empty($_POST["v_proxy_template"])) {
					$v_proxy_template = $_POST["v_proxy_template"];
				}
				if (!empty($_POST["v_proxy_url"])) {
					$v_proxy_url = $_POST["v_proxy_url"];
				}
				exec(
					HESTIA_CMD .
						"v-change-web-domain-proxy-tpl " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($v_proxy_template) .
						" " .
						quoteshellarg($ext) .
						" 'no'" .
						" " .
						quoteshellarg($v_proxy_url),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				$v_proxy_ext = str_replace(",", ", ", $ext);
				unset($output);
				$restart_proxy = "yes";
			}
		}

		// Add proxy support
		if (
			!empty($_SESSION["PROXY_SYSTEM"]) &&
			empty($v_proxy) &&
			!empty($_POST["v_proxy"]) &&
			empty($_SESSION["error_msg"])
		) {
			$v_proxy_template = $_POST["v_proxy_template"];
			$v_proxy_url = $_POST["v_proxy_url"];
			if (!empty($_POST["v_proxy_ext"])) {
				$ext = preg_replace("/\n/", " ", $_POST["v_proxy_ext"]);
				$ext = preg_replace("/,/", " ", $ext);
				$ext = preg_replace("/\s+/", " ", $ext);
				$ext = trim($ext);
				$ext = str_replace(" ", ",", $ext);
				$v_proxy_ext = str_replace(",", ", ", $ext);
			}
			exec(
				HESTIA_CMD .
					"v-add-web-domain-proxy " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					quoteshellarg($v_proxy_template) .
					" " .
					quoteshellarg($ext) .
					" 'no'" .
					" " .
					quoteshellarg($v_proxy_url),
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$restart_proxy = "yes";
		}
	}
	// Change aliases
	if (empty($_SESSION["error_msg"])) {
		$waliases = preg_replace("/\n/", " ", $_POST["v_aliases"]);
		$waliases = preg_replace("/,/", " ", $waliases);
		$waliases = preg_replace("/\s+/", " ", $waliases);
		$waliases = trim($waliases);
		$aliases = explode(" ", $waliases);
		$v_aliases = str_replace(" ", "\n", $waliases);
		$result = array_diff($valiases, $aliases);
		foreach ($result as $alias) {
			if (empty($_SESSION["error_msg"]) && !empty($alias)) {
				$restart_web = "yes";
				$restart_proxy = "yes";
				exec(
					HESTIA_CMD .
						"v-delete-web-domain-alias " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($alias) .
						" 'no'",
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);

				if (empty($_SESSION["error_msg"])) {
					exec(
						HESTIA_CMD . "v-list-dns-domain " . $user . " " . quoteshellarg($v_domain),
						$output,
						$return_var,
					);
					unset($output);
					if ($return_var == 0) {
						exec(
							HESTIA_CMD .
								"v-delete-dns-on-web-alias " .
								$user .
								" " .
								quoteshellarg($v_domain) .
								" " .
								quoteshellarg($alias) .
								" 'no'",
							$output,
							$return_var,
						);
						check_return_code($return_var, $output);
						unset($output);
						$restart_dns = "yes";
					}
				}
			}
		}

		$result = array_diff($aliases, $valiases);
		foreach ($result as $alias) {
			if (empty($_SESSION["error_msg"]) && !empty($alias)) {
				$restart_web = "yes";
				$restart_proxy = "yes";
				exec(
					HESTIA_CMD .
						"v-add-web-domain-alias " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($alias) .
						" 'no'",
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
				if (empty($_SESSION["error_msg"])) {
					exec(
						HESTIA_CMD . "v-list-dns-domain " . $user . " " . quoteshellarg($v_domain),
						$output,
						$return_var,
					);
					unset($output);
					if ($return_var == 0) {
						exec(
							HESTIA_CMD .
								"v-add-dns-on-web-alias " .
								$user .
								" " .
								quoteshellarg($alias) .
								" " .
								quoteshellarg($v_newip_public ?: $v_ip_public) .
								" no",
							$output,
							$return_var,
						);
						check_return_code($return_var, $output);
						unset($output);
						$restart_dns = "yes";
					}
				}
			}
		}

		// Regenerate LE if aliases are different
		if (
			!empty($_POST["v_ssl"]) &&
			$v_letsencrypt == "yes" &&
			!empty($_POST["v_letsencrypt"]) &&
			empty($_SESSION["error_msg"])
		) {
			// If aliases are different from stored aliases
			if (array_diff($valiases, $aliases) || array_diff($aliases, $valiases)) {
				// Add certificate with new aliases
				$l_aliases = str_replace("\n", ",", $v_aliases);
				exec(
					HESTIA_CMD .
						"v-add-letsencrypt-domain " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($l_aliases) .
						" ''",
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
				$v_letsencrypt = "yes";
				$v_ssl = "yes";
				$restart_web = "yes";
				$restart_proxy = "yes";

				exec(
					HESTIA_CMD .
						"v-list-web-domain-ssl " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" json",
					$output,
					$return_var,
				);
				$ssl_str = json_decode(implode("", $output), true);
				unset($output);
				$v_ssl_crt = $ssl_str[$v_domain]["CRT"];
				$v_ssl_key = $ssl_str[$v_domain]["KEY"];
				$v_ssl_ca = $ssl_str[$v_domain]["CA"];
				$v_ssl_subject = $ssl_str[$v_domain]["SUBJECT"];
				$v_ssl_aliases = $ssl_str[$v_domain]["ALIASES"];
				$v_ssl_not_before = $ssl_str[$v_domain]["NOT_BEFORE"];
				$v_ssl_not_after = $ssl_str[$v_domain]["NOT_AFTER"];
				$v_ssl_signature = $ssl_str[$v_domain]["SIGNATURE"];
				$v_ssl_pub_key = $ssl_str[$v_domain]["PUB_KEY"];
				$v_ssl_issuer = $ssl_str[$v_domain]["ISSUER"];
			}
		}

		if (!empty($v_stats) && $_POST["v_stats"] == $v_stats && empty($_SESSION["error_msg"])) {
			// Update statistics configuration when changing domain aliases
			$v_stats = quoteshellarg($_POST["v_stats"]);
			exec(
				HESTIA_CMD .
					"v-change-web-domain-stats " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$v_stats,
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
		}
	}

	// Change SSL certificate
	if (
		$v_letsencrypt == "no" &&
		empty($_POST["v_letsencrypt"]) &&
		$v_ssl == "yes" &&
		!empty($_POST["v_ssl"]) &&
		empty($_SESSION["error_msg"])
	) {
		if (
			$v_ssl_crt != str_replace("\r\n", "\n", $_POST["v_ssl_crt"]) ||
			$v_ssl_key != str_replace("\r\n", "\n", $_POST["v_ssl_key"]) ||
			$v_ssl_ca != str_replace("\r\n", "\n", $_POST["v_ssl_ca"])
		) {
			exec("mktemp -d", $mktemp_output, $return_var);
			$tmpdir = $mktemp_output[0];

			// Certificate
			if (!empty($_POST["v_ssl_crt"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".crt", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_crt"]));
				fwrite($fp, "\n");
				fclose($fp);
			}

			// Key
			if (!empty($_POST["v_ssl_key"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".key", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_key"]));
				fwrite($fp, "\n");
				fclose($fp);
			}

			// CA
			if (!empty($_POST["v_ssl_ca"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".ca", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_ca"]));
				fwrite($fp, "\n");
				fclose($fp);
			}

			exec(
				HESTIA_CMD .
					"v-change-web-domain-sslcert " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$tmpdir .
					" 'no'",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$restart_web = "yes";
			$restart_proxy = "yes";

			exec(
				HESTIA_CMD .
					"v-list-web-domain-ssl " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" json",
				$output,
				$return_var,
			);
			$ssl_str = json_decode(implode("", $output), true);
			unset($output);
			$v_ssl_crt = $ssl_str[$v_domain]["CRT"];
			$v_ssl_key = $ssl_str[$v_domain]["KEY"];
			$v_ssl_ca = $ssl_str[$v_domain]["CA"];
			$v_ssl_subject = $ssl_str[$v_domain]["SUBJECT"];
			$v_ssl_aliases = $ssl_str[$v_domain]["ALIASES"];
			$v_ssl_not_before = $ssl_str[$v_domain]["NOT_BEFORE"];
			$v_ssl_not_after = $ssl_str[$v_domain]["NOT_AFTER"];
			$v_ssl_signature = $ssl_str[$v_domain]["SIGNATURE"];
			$v_ssl_pub_key = $ssl_str[$v_domain]["PUB_KEY"];
			$v_ssl_issuer = $ssl_str[$v_domain]["ISSUER"];

			// Cleanup certificate tempfiles
			if (!empty($_POST["v_ssl_crt"])) {
				unlink($tmpdir . "/" . $v_domain . ".crt");
			}
			if (!empty($_POST["v_ssl_key"])) {
				unlink($tmpdir . "/" . $v_domain . ".key");
			}
			if (!empty($_POST["v_ssl_ca"])) {
				unlink($tmpdir . "/" . $v_domain . ".ca");
			}
			rmdir($tmpdir);
		}
	}

	// Delete Lets Encrypt support
	if (
		$v_letsencrypt == "yes" &&
		(empty($_POST["v_letsencrypt"]) || empty($_POST["v_ssl"])) &&
		empty($_SESSION["error_msg"])
	) {
		exec(
			HESTIA_CMD .
				"v-delete-letsencrypt-domain " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" ''",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_crt = "";
		$v_ssl_key = "";
		$v_ssl_ca = "";
		$v_letsencrypt = "no";
		$v_letsencrypt_deleted = "yes";
		$v_ssl = "no";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Delete SSL certificate
	if ($v_ssl == "yes" && empty($_POST["v_ssl"]) && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD .
				"v-delete-web-domain-ssl " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" 'no'",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_crt = "";
		$v_ssl_key = "";
		$v_ssl_ca = "";
		$v_ssl = "no";
		$v_ssl_forcessl = "no";
		$v_ssl_hsts = "no";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Add Lets Encrypt support
	if (
		!empty($_POST["v_ssl"]) &&
		$v_letsencrypt == "no" &&
		!empty($_POST["v_letsencrypt"]) &&
		empty($_SESSION["error_msg"])
	) {
		$l_aliases = str_replace("\n", ",", $v_aliases);
		exec(
			HESTIA_CMD .
				"v-add-letsencrypt-domain " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				quoteshellarg($l_aliases) .
				" ''",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		if ($return_var != 0) {
			$v_letsencrypt = "no";
		} else {
			$v_letsencrypt = "yes";
		}
		$v_ssl = "yes";
		if ($_POST["v_ssl_forcessl"] == "on") {
			$v_ssl_forcessl = "yes";
		} else {
			$v_ssl_forcessl = "no";
		}
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Add SSL certificate
	if (
		$v_ssl == "no" &&
		!empty($_POST["v_ssl"]) &&
		empty($v_letsencrypt_deleted) &&
		empty($_SESSION["error_msg"])
	) {
		if (empty($_POST["v_ssl_crt"])) {
			$errors[] = "ssl certificate";
		}
		if (empty($_POST["v_ssl_key"])) {
			$errors[] = "ssl key";
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
		} else {
			exec("mktemp -d", $mktemp_output, $return_var);
			$tmpdir = $mktemp_output[0];

			// Certificate
			if (!empty($_POST["v_ssl_crt"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".crt", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_crt"]));
				fclose($fp);
			}

			// Key
			if (!empty($_POST["v_ssl_key"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".key", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_key"]));
				fclose($fp);
			}

			// CA
			if (!empty($_POST["v_ssl_ca"])) {
				$fp = fopen($tmpdir . "/" . $v_domain . ".ca", "w");
				fwrite($fp, str_replace("\r\n", "\n", $_POST["v_ssl_ca"]));
				fclose($fp);
			}
			//keep using the original value for v_ssl_home
			exec(
				HESTIA_CMD .
					"v-add-web-domain-ssl " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$tmpdir .
					" " .
					quoteshellarg($v_ssl_home) .
					" 'no'",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$v_ssl = "yes";
			$restart_web = "yes";
			$restart_proxy = "yes";

			exec(
				HESTIA_CMD .
					"v-list-web-domain-ssl " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" json",
				$output,
				$return_var,
			);
			$ssl_str = json_decode(implode("", $output), true);
			unset($output);
			$v_ssl_crt = $ssl_str[$v_domain]["CRT"];
			$v_ssl_key = $ssl_str[$v_domain]["KEY"];
			$v_ssl_ca = $ssl_str[$v_domain]["CA"];
			$v_ssl_subject = $ssl_str[$v_domain]["SUBJECT"];
			$v_ssl_aliases = $ssl_str[$v_domain]["ALIASES"];
			$v_ssl_not_before = $ssl_str[$v_domain]["NOT_BEFORE"];
			$v_ssl_not_after = $ssl_str[$v_domain]["NOT_AFTER"];
			$v_ssl_signature = $ssl_str[$v_domain]["SIGNATURE"];
			$v_ssl_pub_key = $ssl_str[$v_domain]["PUB_KEY"];
			$v_ssl_issuer = $ssl_str[$v_domain]["ISSUER"];

			// Cleanup certificate tempfiles
			if (!empty($_POST["v_ssl_crt"])) {
				unlink($tmpdir . "/" . $v_domain . ".crt");
			}
			if (!empty($_POST["v_ssl_key"])) {
				unlink($tmpdir . "/" . $v_domain . ".key");
			}
			if (!empty($_POST["v_ssl_ca"])) {
				unlink($tmpdir . "/" . $v_domain . ".ca");
			}
			rmdir($tmpdir);
		}
	}

	// Add Force SSL
	if (
		!empty($_POST["v_ssl_forcessl"]) &&
		!empty($_POST["v_ssl"]) &&
		empty($_SESSION["error_msg"])
	) {
		exec(
			HESTIA_CMD . "v-add-web-domain-ssl-force " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_forcessl = "yes";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Add SSL HSTS
	if (!empty($_POST["v_ssl_hsts"]) && !empty($_POST["v_ssl"]) && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-add-web-domain-ssl-hsts " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_hsts = "yes";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Delete Force SSL
	if (
		$v_ssl_forcessl == "yes" &&
		empty($_POST["v_ssl_forcessl"]) &&
		empty($_SESSION["error_msg"])
	) {
		exec(
			HESTIA_CMD . "v-delete-web-domain-ssl-force " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_forcessl = "no";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Delete SSL HSTS
	if ($v_ssl_hsts == "yes" && empty($_POST["v_ssl_hsts"]) && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-delete-web-domain-ssl-hsts " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_ssl_hsts = "no";
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	// Delete web stats
	if (!empty($v_stats) && $_POST["v_stats"] == "none" && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-delete-web-domain-stats " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_stats = "";
	}

	// Change web stats engine
	if (!empty($v_stats) && $_POST["v_stats"] != $v_stats && empty($_SESSION["error_msg"])) {
		$v_stats = quoteshellarg($_POST["v_stats"]);
		exec(
			HESTIA_CMD .
				"v-change-web-domain-stats " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				$v_stats,
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Add web stats
	if (empty($v_stats) && $_POST["v_stats"] != "none" && empty($_SESSION["error_msg"])) {
		$v_stats = quoteshellarg($_POST["v_stats"]);
		exec(
			HESTIA_CMD .
				"v-add-web-domain-stats " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" " .
				$v_stats,
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Delete web stats authorization
	if (!empty($v_stats_user) && empty($_POST["v_stats_auth"]) && empty($_SESSION["error_msg"])) {
		exec(
			HESTIA_CMD . "v-delete-web-domain-stats-user " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		$v_stats_user = "";
		$v_stats_password = "";
	}

	// Change web stats user or password
	if (empty($v_stats_user) && !empty($_POST["v_stats_auth"]) && empty($_SESSION["error_msg"])) {
		if (empty($_POST["v_stats_user"])) {
			$errors[] = _("Username");
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
		} else {
			$v_stats_user = quoteshellarg($_POST["v_stats_user"]);
			$v_stats_password = tempnam("/tmp", "vst");
			$fp = fopen($v_stats_password, "w");
			fwrite($fp, $_POST["v_stats_password"] . "\n");
			fclose($fp);
			exec(
				HESTIA_CMD .
					"v-add-web-domain-stats-user " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$v_stats_user .
					" " .
					$v_stats_password,
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			unlink($v_stats_password);
			$v_stats_password = quoteshellarg($_POST["v_stats_password"]);
		}
	}

	// Add web stats authorization
	if (!empty($v_stats_user) && !empty($_POST["v_stats_auth"]) && empty($_SESSION["error_msg"])) {
		if (empty($_POST["v_stats_user"])) {
			$errors[] = _("Username");
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
		if (
			$v_stats_user != $_POST["v_stats_user"] ||
			(!empty($_POST["v_stats_password"]) && empty($_SESSION["error_msg"]))
		) {
			$v_stats_user = quoteshellarg($_POST["v_stats_user"]);
			$v_stats_password = tempnam("/tmp", "vst");
			$fp = fopen($v_stats_password, "w");
			fwrite($fp, $_POST["v_stats_password"] . "\n");
			fclose($fp);
			exec(
				HESTIA_CMD .
					"v-add-web-domain-stats-user " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$v_stats_user .
					" " .
					$v_stats_password,
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			unlink($v_stats_password);
			$v_stats_password = quoteshellarg($_POST["v_stats_password"]);
		}
	}

	// Update ftp account
	if (!empty($_POST["v_ftp_user"])) {
		$v_ftp_users_updated = [];
		foreach ($_POST["v_ftp_user"] as $i => $v_ftp_user_data) {
			if (empty($v_ftp_user_data["v_ftp_user"])) {
				continue;
			}

			$v_ftp_user_data["v_ftp_user"] = preg_replace(
				"/^" . $user . "_/i",
				"",
				$v_ftp_user_data["v_ftp_user"],
			);
			if ($v_ftp_user_data["is_new"] == 1 && !empty($_POST["v_ftp"])) {
				if (
					!empty($v_ftp_user_data["v_ftp_email"]) &&
					!filter_var($v_ftp_user_data["v_ftp_email"], FILTER_VALIDATE_EMAIL)
				) {
					$_SESSION["error_msg"] = _("Please enter a valid email address.");
				}
				if (empty($v_ftp_user_data["v_ftp_user"])) {
					$errors[] = "ftp user";
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

				// Add ftp account
				$v_ftp_username_for_emailing = $v_ftp_user_data["v_ftp_user"];
				$v_ftp_username = $v_ftp_user_data["v_ftp_user"];
				$v_ftp_username_full = $user . "_" . $v_ftp_user_data["v_ftp_user"];
				$v_ftp_user = quoteshellarg($v_ftp_username);
				$v_ftp_path = quoteshellarg(trim($v_ftp_user_data["v_ftp_path"]));
				if (empty($_SESSION["error_msg"])) {
					$v_ftp_password = tempnam("/tmp", "vst");
					$fp = fopen($v_ftp_password, "w");
					fwrite($fp, $v_ftp_user_data["v_ftp_password"] . "\n");
					fclose($fp);
					exec(
						HESTIA_CMD .
							"v-add-web-domain-ftp " .
							$user .
							" " .
							quoteshellarg($v_domain) .
							" " .
							$v_ftp_user .
							" " .
							$v_ftp_password .
							" " .
							$v_ftp_path,
						$output,
						$return_var,
					);
					check_return_code($return_var, $output);
					if (!empty($v_ftp_user_data["v_ftp_email"]) && empty($_SESSION["error_msg"])) {
						$to = $v_ftp_user_data["v_ftp_email"];
						$template = get_email_template("ftp_credentials", $_SESSION["language"]);
						$hostname = get_hostname();
						$from = !empty($_SESSION["FROM_EMAIL"])
							? $_SESSION["FROM_EMAIL"]
							: "noreply@" . $hostname;
						$from_name = !empty($_SESSION["FROM_NAME"])
							? $_SESSION["FROM_NAME"]
							: $_SESSION["APP_NAME"];
						$template = get_email_template(
							"ftpaccount_created",
							$data[$user]["LANGUAGE"],
						);
						if (!empty($template)) {
							preg_match("/<subject>(.*?)<\/subject>/si", $template, $matches);
							$subject = $matches[1];
							$subject = str_replace(
								["{{hostname}}", "{{appname}}", "{{username}}", "{{domain}}"],
								[
									get_hostname(),
									$_SESSION["APP_NAME"],
									$user_plain . "_" . $v_ftp_username_for_emailing,
									$v_domain,
								],
								$subject,
							);
							$template = str_replace($matches[0], "", $template);
						} else {
							$template = _(
								"FTP account has been created and ready to use.\n" .
									"\n" .
									"Hostname: {{domain}}\n" .
									"Username: {{username}}\n" .
									"Password: {{password}}\n" .
									"\n" .
									"Best regards,\n" .
									"\n" .
									"--\n" .
									"{{appname}}",
							);
						}
						if (empty($subject)) {
							$subject = str_replace(
								["{{subject}}", "{{hostname}}", "{{appname}}"],
								[
									sprintf(
										_("FTP Account Credentials: %s"),
										$user_plain . "_" . $v_ftp_username_for_emailing,
									),
									get_hostname(),
									$_SESSION["APP_NAME"],
								],
								$_SESSION["SUBJECT_EMAIL"],
							);
						}

						$mailtext = translate_email($template, [
							"domain" => htmlentities($v_domain),
							"username" => htmlentities(
								$user_plain . "_" . $v_ftp_username_for_emailing,
							),
							"password" => htmlentities($v_ftp_user_data["v_ftp_password"]),
							"appname" => $_SESSION["APP_NAME"],
						]);

						send_email($to, $subject, $mailtext, $from, $from_name);
						unset($v_ftp_email);
					}
					unset($output);
					unlink($v_ftp_password);
					$v_ftp_password = quoteshellarg($v_ftp_user_data["v_ftp_password"]);
				}

				if ($return_var == 0) {
					$v_ftp_password = "";
					$v_ftp_user_data["is_new"] = 0;
				} else {
					$v_ftp_user_data["is_new"] = 1;
				}

				$v_ftp_users_updated[] = [
					"is_new" => empty($_SESSION["error_msg"]) ? 0 : 1,
					"v_ftp_user" => $v_ftp_username_full,
					"v_ftp_password" => $v_ftp_password,
					"v_ftp_path" => $v_ftp_user_data["v_ftp_path"],
					"v_ftp_email" => $v_ftp_user_data["v_ftp_email"],
					"v_ftp_pre_path" => $v_ftp_user_prepath,
				];

				continue;
			}

			// Delete FTP account
			if ($v_ftp_user_data["delete"] == 1) {
				$v_ftp_username = $user_plain . "_" . $v_ftp_user_data["v_ftp_user"];
				exec(
					HESTIA_CMD .
						"v-delete-web-domain-ftp " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($v_ftp_username),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);

				continue;
			}

			if (!empty($_POST["v_ftp"])) {
				if (empty($v_ftp_user_data["v_ftp_user"])) {
					$errors[] = _("Username");
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

				// Change FTP account path
				$v_ftp_username_for_emailing = $v_ftp_user_data["v_ftp_user"];
				$v_ftp_username = $user_plain . "_" . $v_ftp_user_data["v_ftp_user"]; //preg_replace("/^".$user."_/", "", $v_ftp_user_data['v_ftp_user']);
				$v_ftp_username = quoteshellarg($v_ftp_username);
				$v_ftp_path = quoteshellarg(trim($v_ftp_user_data["v_ftp_path"]));
				if (quoteshellarg(trim($v_ftp_user_data["v_ftp_path_prev"])) != $v_ftp_path) {
					exec(
						HESTIA_CMD .
							"v-change-web-domain-ftp-path " .
							$user .
							" " .
							quoteshellarg($v_domain) .
							" " .
							$v_ftp_username .
							" " .
							$v_ftp_path,
						$output,
						$return_var,
					);
					check_return_code($return_var, $output);
					unset($output);
				}
				// Change FTP account password
				if (!empty($v_ftp_user_data["v_ftp_password"])) {
					$v_ftp_password = tempnam("/tmp", "vst");
					$fp = fopen($v_ftp_password, "w");
					fwrite($fp, $v_ftp_user_data["v_ftp_password"] . "\n");
					fclose($fp);
					exec(
						HESTIA_CMD .
							"v-change-web-domain-ftp-password " .
							$user .
							" " .
							quoteshellarg($v_domain) .
							" " .
							$v_ftp_username .
							" " .
							$v_ftp_password,
						$output,
						$return_var,
					);
					unlink($v_ftp_password);
				}
				if (!empty($v_ftp_user_data["v_ftp_email"]) && empty($_SESSION["error_msg"])) {
					$to = $v_ftp_user_data["v_ftp_email"];
					$template = get_email_template("ftp_credentials", $_SESSION["language"]);
					$hostname = get_hostname();
					$from = !empty($_SESSION["FROM_EMAIL"])
						? $_SESSION["FROM_EMAIL"]
						: "noreply@" . $hostname;
					$from_name = !empty($_SESSION["FROM_NAME"])
						? $_SESSION["FROM_NAME"]
						: $_SESSION["APP_NAME"];
					$template = get_email_template("ftpaccount_created", $data[$user]["LANGUAGE"]);
					if (!empty($template)) {
						preg_match("/<subject>(.*?)<\/subject>/si", $template, $matches);
						$subject = $matches[1];
						$subject = str_replace(
							["{{hostname}}", "{{appname}}", "{{username}}", "{{domain}}"],
							[
								get_hostname(),
								$_SESSION["APP_NAME"],
								$user_plain . "_" . $v_ftp_username_for_emailing,
								$v_domain,
							],
							$subject,
						);
						$template = str_replace($matches[0], "", $template);
					} else {
						$template = _(
							"FTP account has been created and ready to use.\n" .
								"\n" .
								"Hostname: {{domain}}\n" .
								"Username: {{username}}\n" .
								"Password: {{password}}\n" .
								"\n" .
								"Best regards,\n" .
								"\n" .
								"--\n" .
								"{{appname}}",
						);
					}
					if (empty($subject)) {
						$subject = str_replace(
							["{{subject}}", "{{hostname}}", "{{appname}}"],
							[
								sprintf(
									_("FTP Account Credentials: %s"),
									$user_plain . "_" . $v_ftp_username_for_emailing,
								),
								get_hostname(),
								$_SESSION["APP_NAME"],
							],
							$_SESSION["SUBJECT_EMAIL"],
						);
					}

					$mailtext = translate_email($template, [
						"domain" => $v_domain,
						"username" => $user_plain . "_" . $v_ftp_username_for_emailing,
						"password" => $v_ftp_user_data["v_ftp_password"],
						"appname" => $_SESSION["APP_NAME"],
					]);

					send_email($to, $subject, $mailtext, $from, $from_name);
					unset($v_ftp_email);
				}
				if (empty($v_ftp_user_data["v_ftp_email"])) {
					$v_ftp_user_data["v_ftp_email"] = "";
				}
				$v_ftp_users_updated[] = [
					"is_new" => 0,
					"v_ftp_user" => $v_ftp_username,
					"v_ftp_password" => $v_ftp_user_data["v_ftp_password"],
					"v_ftp_path" => $v_ftp_user_data["v_ftp_path"],
					"v_ftp_email" => $v_ftp_user_data["v_ftp_email"],
					"v_ftp_pre_path" => $v_ftp_user_prepath,
				];
			}
		}
	}
	//custom docoot with check box disabled
	if (!empty($v_custom_doc_root) && empty($_POST["v_custom_doc_root_check"])) {
		exec(
			HESTIA_CMD .
				"v-change-web-domain-docroot " .
				$user .
				" " .
				quoteshellarg($v_domain) .
				" default",
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		unset($_POST["v-custom-doc-domain"], $_POST["v-custom-doc-folder"]);
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	if (
		!empty($_POST["v-custom-doc-domain"]) &&
		!empty($_POST["v_custom_doc_root_check"]) &&
		$v_custom_doc_root_prepath . $v_custom_doc_domain . "/public_html" . $v_custom_doc_folder !=
			$v_custom_doc_root
	) {
		if ($_POST["v-custom-doc-domain"] == $v_domain && empty($_POST["v-custom-doc-folder"])) {
			exec(
				HESTIA_CMD .
					"v-change-web-domain-docroot " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" default",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
		} else {
			$v_custom_doc_folder = quoteshellarg(rtrim($_POST["v-custom-doc-folder"], "/"));
			$v_custom_doc_domain = quoteshellarg($_POST["v-custom-doc-domain"]);

			exec(
				HESTIA_CMD .
					"v-change-web-domain-docroot " .
					$user .
					" " .
					quoteshellarg($v_domain) .
					" " .
					$v_custom_doc_domain .
					" " .
					$v_custom_doc_folder .
					" yes",
				$output,
				$return_var,
			);
			check_return_code($return_var, $output);
			unset($output);
			$v_custom_doc_root = 1;
		}
		$restart_web = "yes";
		$restart_proxy = "yes";
	} else {
		unset($v_custom_doc_root);
	}

	if (!empty($v_redirect) && empty($_POST["v-redirect-checkbox"])) {
		exec(
			HESTIA_CMD . "v-delete-web-domain-redirect " . $user . " " . quoteshellarg($v_domain),
			$output,
			$return_var,
		);
		check_return_code($return_var, $output);
		unset($output);
		unset($_POST["v-redirect"]);
		$restart_web = "yes";
		$restart_proxy = "yes";
	}

	if (!empty($_POST["v-redirect"]) && !empty($_POST["v-redirect-checkbox"])) {
		if (empty($v_redirect)) {
			if ($_POST["v-redirect"] == "custom" && empty($_POST["v-redirect-custom"])) {
			} else {
				if ($_POST["v-redirect"] == "custom") {
					$_POST["v-redirect"] = $_POST["v-redirect-custom"];
				}
				exec(
					HESTIA_CMD .
						"v-add-web-domain-redirect " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($_POST["v-redirect"]) .
						" " .
						quoteshellarg($_POST["v-redirect-code"]),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
				$restart_web = "yes";
				$restart_proxy = "yes";
			}
		} else {
			if ($_POST["v-redirect"] == "custom") {
				$_POST["v-redirect"] = $_POST["v-redirect-custom"];
			}
			if (
				$_POST["v-redirect"] != $v_redirect ||
				$_POST["v-redirect-code"] != $v_redirect_code
			) {
				exec(
					HESTIA_CMD .
						"v-add-web-domain-redirect " .
						$user .
						" " .
						quoteshellarg($v_domain) .
						" " .
						quoteshellarg($_POST["v-redirect"]) .
						" " .
						quoteshellarg($_POST["v-redirect-code"]),
					$output,
					$return_var,
				);
				check_return_code($return_var, $output);
				unset($output);
				$restart_web = "yes";
				$restart_proxy = "yes";
			}
		}
	}
	// Restart web server
	if (!empty($restart_web) && empty($_SESSION["error_msg"])) {
		exec(HESTIA_CMD . "v-restart-web", $output, $return_var);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Restart proxy server
	if (
		!empty($_SESSION["PROXY_SYSTEM"]) &&
		!empty($restart_proxy) &&
		empty($_SESSION["error_msg"])
	) {
		exec(HESTIA_CMD . "v-restart-proxy", $output, $return_var);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Restart dns server
	if (!empty($restart_dns) && empty($_SESSION["error_msg"])) {
		exec(HESTIA_CMD . "v-restart-dns", $output, $return_var);
		check_return_code($return_var, $output);
		unset($output);
	}

	// Set success message
	if (empty($_SESSION["error_msg"])) {
		$_SESSION["ok_msg"] = _("Changes have been saved.");
		header("Location: /edit/web/?domain=" . $v_domain);
		exit();
	}
}

$v_ftp_users_raw = explode(":", $v_ftp_user);
$v_ftp_users_paths_raw = explode(":", $data[$v_domain]["FTP_PATH"]);
$v_ftp_users = [];
foreach ($v_ftp_users_raw as $v_ftp_user_index => $v_ftp_user_val) {
	if (empty($v_ftp_user_val)) {
		continue;
	}
	$v_ftp_users[] = [
		"is_new" => 0,
		"v_ftp_user" => preg_replace("/^" . $user_plain . "_/", "", $v_ftp_user_val),
		"v_ftp_password" => $v_ftp_password,
		"v_ftp_path" => isset($v_ftp_users_paths_raw[$v_ftp_user_index])
			? $v_ftp_users_paths_raw[$v_ftp_user_index]
			: "",
		"v_ftp_email" => $v_ftp_email,
		"v_ftp_pre_path" => $v_ftp_user_prepath,
	];
}

if (empty($v_ftp_users)) {
	$v_ftp_user = null;
	$v_ftp_users[] = [
		"is_new" => 1,
		"v_ftp_user" => "",
		"v_ftp_password" => "",
		"v_ftp_path" => isset($v_ftp_users_paths_raw[$v_ftp_user_index])
			? $v_ftp_users_paths_raw[$v_ftp_user_index]
			: "",
		"v_ftp_email" => "",
		"v_ftp_pre_path" => $v_ftp_user_prepath,
	];
}

// set default pre path for newly created users
$v_ftp_pre_path_new_user = $v_ftp_user_prepath;
if (isset($v_ftp_users_updated)) {
	$v_ftp_users = $v_ftp_users_updated;
	if (empty($v_ftp_users_updated)) {
		$v_ftp_user = null;
		$v_ftp_users[] = [
			"is_new" => 1,
			"v_ftp_user" => "",
			"v_ftp_password" => "",
			"v_ftp_path" => isset($v_ftp_users_paths_raw[$v_ftp_user_index])
				? $v_ftp_users_paths_raw[$v_ftp_user_index]
				: "",
			"v_ftp_email" => "",
			"v_ftp_pre_path" => $v_ftp_user_prepath,
		];
	}
}

// Render page
render_page($user, $TAB, "edit_web");

// Flush session messages
unset($_SESSION["error_msg"]);
unset($_SESSION["ok_msg"]);
