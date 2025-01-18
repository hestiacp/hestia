<?php
use function Hestiacp\quoteshellarg\quoteshellarg;

ob_start();
$TAB = "CRON";

include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

// Edit as someone else?
if ($_SESSION["userContext"] === "admin" && !empty($_GET["user"])) {
	$user = quoteshellarg($_GET["user"]);
}

// Check job id
if (empty($_GET["job"])) {
	header("Location: /list/cron/");
	exit();
}

// List cron job
$v_job = quoteshellarg($_GET["job"]);
exec(HESTIA_CMD . "v-list-cron-job " . $user . " " . $v_job . " 'json'", $output, $return_var);
check_return_code_redirect($return_var, $output, "/list/cron/");

$data = json_decode(implode("", $output), true);
unset($output);

// Parse cron job
$v_username = $user;
$v_job = $_GET["job"];
$v_min = $data[$v_job]["MIN"];
$v_hour = $data[$v_job]["HOUR"];
$v_day = $data[$v_job]["DAY"];
$v_month = $data[$v_job]["MONTH"];
$v_wday = $data[$v_job]["WDAY"];
$v_cmd = base64_decode($data[$v_job]["CMD"]);
$v_date = $data[$v_job]["DATE"];
$v_time = $data[$v_job]["TIME"];
$v_suspended = $data[$v_job]["SUSPENDED"];
if ($v_suspended == "yes") {
	$v_status = "suspended";
} else {
	$v_status = "active";
}

// Check POST request
if (!empty($_POST["save"])) {
	// Check token
	verify_csrf($_POST);

	$v_username = $user;
	$v_job = quoteshellarg($_GET["job"]);
	$v_min = quoteshellarg($_POST["v_min"]);
	$v_hour = quoteshellarg($_POST["v_hour"]);
	$v_day = quoteshellarg($_POST["v_day"]);
	$v_month = quoteshellarg($_POST["v_month"]);
	$v_wday = quoteshellarg($_POST["v_wday"]);
	$v_cmd = quoteshellarg($_POST["v_cmd"]);

	// Save changes
	exec(
		HESTIA_CMD .
			"v-change-cron-job " .
			$user .
			" " .
			$v_job .
			" " .
			$v_min .
			" " .
			$v_hour .
			" " .
			$v_day .
			" " .
			$v_month .
			" " .
			$v_wday .
			" " .
			$v_cmd,
		$output,
		$return_var,
	);
	check_return_code($return_var, $output);
	unset($output);

	$v_cmd = $_POST["v_cmd"];

	// Set success message
	if (empty($_SESSION["error_msg"])) {
		$_SESSION["ok_msg"] = _("Changes have been saved.");
	}
}

// Get current system time
exec(HESTIA_CMD . "v-get-sys-timezone", $output, $return_var);
date_default_timezone_set($output[0]);
$current_timestamp = time();

// Render page
render_page($user, $TAB, "edit_cron");

// Flush session messages
unset($_SESSION["error_msg"]);
unset($_SESSION["ok_msg"]);
