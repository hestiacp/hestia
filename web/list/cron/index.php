<?php
$TAB = "CRON";

// Main include
include $_SERVER["DOCUMENT_ROOT"] . "/inc/main.php";

// Data

exec(HESTIA_CMD . "v-list-cron-jobs $user json", $output, $return_var);
// Fix quotes and backslash
foreach ($output as $key => $value) {
	$newvalue = str_replace("\\\"", "|", $value);
	$newvalue = str_replace("\"", "'", $newvalue);
	$newvalue = str_replace("\\", "\\\\", $newvalue);
	$newvalue = str_replace("|", "\\\"", $newvalue);
	$output[$key] = str_replace("'", "\"", $newvalue);
}
$data = json_decode(implode("", $output), true);
if ($_SESSION["userSortOrder"] == "name") {
	ksort($data);
} else {
	$data = array_reverse($data, true);
}
unset($output);

// Render page
render_page($user, $TAB, "list_cron");

// Back uri
$_SESSION["back"] = $_SERVER["REQUEST_URI"];
