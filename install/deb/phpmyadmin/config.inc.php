<?php
/* PHPmyadmin config for Hestia 1.3.3 > */
/* vim: set expandtab sw=4 ts=4 sts=4: */
/**
 * All directives are explained in documentation in the doc/ folder
 * or at <https://docs.phpmyadmin.net/>.
 *
 * @package PhpMyAdmin
 */
declare(strict_types=1);

/**
 * This is needed for cookie based authentication to encrypt password in
 * cookie. Needs to be 32 chars long.
 */
$cfg["blowfish_secret"] = "%blowfish_secret%"; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */

/**
 * Directories for saving/loading files from server
 */
$cfg["UploadDir"] = "";
$cfg["SaveDir"] = "";

/**
 * You can find more configuration options in the documentation
 * in the doc/ folder or at <https://docs.phpmyadmin.net/>.
 */

//start with 1 other wise it doesn't work
$i = 1;
foreach (glob("/etc/phpmyadmin/conf.d/*.php") as $filename) {
	include $filename;
	/*Don't remove / alter code here below this will add SSO support for all servers*/
	//Add Hestia SSO code here
	$i++;
}

/**
 * Put tmp on the right dir
 */
$cfg["TempDir"] = "/tmp";
