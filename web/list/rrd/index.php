<?php

$TAB = 'RRD';

// Main include
include($_SERVER['DOCUMENT_ROOT']."/inc/main.php");

// Check user
if ($_SESSION['userContext'] != 'admin') {
    header('Location: /list/user');
    exit;
}

// Data
exec(HESTIA_CMD."v-list-sys-rrd json", $output, $return_var);
$data = json_decode(implode('', $output), true);
unset($output);

if (empty($_GET['period'])) {
    $period = 'day';
} elseif (!in_array($_GET['period'], array('day', 'week', 'month', 'year'))) {
    $period = 'day';
} else {
    $period = $_GET['period'];
}

// Render page
render_page($user, $TAB, 'list_rrd');

// Back uri
$_SESSION['back'] = $_SERVER['REQUEST_URI'];
