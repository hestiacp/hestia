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

// If data is empty, try to remove the line containing "CMD" in $output and try again
if (empty($data)) {
	foreach ($output as $key => $value) {
		if (strpos($value, "CMD") !== false) {
			$output[$key] = "\"CMD\": \"Cron tab is broken, please press save.\",";
		}
	}
	$data = json_decode(implode("", $output), true);
	// Iterate over the $data object and find the CMD line from each job by checking v-list-cron-job
	foreach ($data as $key => $value) {
		$v_job = $key;
		exec(HESTIA_CMD . "v-list-cron-job " . $user . " " . $v_job . " 'json'", $singleoutput, $return_var);
		// Fix quotes and backslash
		foreach ($singleoutput as $skey => $svalue) {
			$newsvalue = str_replace("\\\"", "|", $svalue);
			$newsvalue = str_replace("\"", "'", $newsvalue);
			$newsvalue = str_replace("\\", "\\\\", $newsvalue);
			$newsvalue = str_replace("|", "\\\"", $newsvalue);
			$singleoutput[$skey] = str_replace("'", "\"", $newsvalue);
		}
		$singledata = json_decode(implode("", $singleoutput), true);
		$data[$v_job]["CMD"] = $singledata[$v_job]["CMD"] ?? "Cron tab is broken, please press save.";
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

// Back uri
$_SESSION["back"] = $_SERVER["REQUEST_URI"];
