<?php
$TAB = "CRON";

// Main include
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

// Retrieve cron job data
exec(HESTIA_CMD . "v-list-cron-jobs $user json", $output, $return_var);

// Try to decode output as json
$data = json_decode(implode("", $output), true);

// if data is empty, but $output doesn't only contain this string {}, set error message
if (empty($data) && implode("", $output) != "{}") {
	$_SESSION["error_msg"] = "Cron jobs could not be retrieved. Contact Server Administrator";
	$data = [];
	$retrieve_error = true;
} else {
	// decode base64 encoded string "CMD" in $data
	foreach ($data as $key => $value) {
		$data[$key]["CMD"] = base64_decode($value["CMD"]);
	}
}

if ($_SESSION["userSortOrder"] == "name") {
	ksort($data);
} else {
	$data = array_reverse($data, true);
}
unset($output);

// Render page
render_page($user, $TAB, "list_cron");

unset($retrieve_error);
// Flush session messages
unset($_SESSION["error_msg"]);
unset($_SESSION["ok_msg"]);

// Back uri
$_SESSION["back"] = $_SERVER["REQUEST_URI"];
