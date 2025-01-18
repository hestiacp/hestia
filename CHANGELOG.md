# Changelog

All notable changes to this project will be documented in this file.

## [1.9.0] - Feature / Major release

### Notes

- To improve security we have deciced to allow users to rename the default admin user. And use a new user "hestia-web" to become the default user to run Hestia on.
- Dropped support Debian 10 due to EOL

### Features

- Added support for PHP 8.4
- Add support for Ubuntu 24.04 Noble release (#4411 #4451)
- Add support for Jailed SSH (#4052 #4245) @rjd222
- Implement CLI for Quick Install Apps (#4443)
- Add support for Directadmin / Cpanel imports ( #4177 #4415 #4426 #4252 #4241)
- Add support for Increamental Backups via Restic
- Add support for Triggers in v-add-mail-domain / v-add-delete-mail-domain #4416 (See Docs)
- Add new Quick Install Apps (#4433, #4509, #4327)
- Add support for Limit CPU and RAM for Each User Using cgroup (#4372 #4325)
- Add Web terminal (#3859)
- Improve email account sidebar layout (#4154)
- Allow Chmod in Filegator #4548

### Bug fixes

- Allow filegator to be translated (#4382 #4275)
- Fix bug caused by new release robthree/twofactorauth (#4410)
- Create .wp-cli folder on create new user (#4403)
- Fix SMTP Relay routing issue (#4389)
- Fix Roundcube permissions (#4387)
- Fix v-add-dns-record when adding TLSA records (#4376)
- Fix handling of Snappymail (#4349)
- Added creation of dovecot.log and permission setup to dovecot installation step (#4352)
- Fix to the Localpart Mail validator so it can accept aliases starting and ending with (#4351)
- Apache2: Enable mod_headers by default. (#4350)
- Update MediaWiki to 1.41.1 (#4344)
- Add support for compressing via GZ or ZSTD (#4300 #4322)
- Simplify spinner styles (#4319)
- Animate deletion of notifications (#4316)
- Update v-run-cli-cmd (#4310)
- Show database server port in notification email (#4301)
- Fixes permissions issue related with Issue #4248 (#4268)
- remove PHP code, and fix installer warning (#4279)
- Prevent \* from expanding in command (#4085)
- Drop v-generate-debug-report (#4266)
- Fix missing dot file backups
- vsftpd use_localtime No #4261
- Fix broken mysql v8 install on Debian (#4259)
- Use standard y/N format in installer to indicate default (#4251)
- Fix broken HTML on login/reset pages (#4247)
- Checks for usernames starting with a alphabetic character. (#4195 #4181)
- Correct formatting of user dir (#4098)
- Add mjs as a file to serve statically (#4240)
- Display system time on cron pages (#4236)
- Patch Dokuwiki installer for issue #3889 (#4229)
- Corrected path to ssl certs (#4202)
- Add value to input type text (#4193)
- Correctly get the session cookie for web terminal (#3969)
- Fix Bug with 403 errors Letsencrypt (#4622)
- Update phpmyadmin.inc to improve loading static files
- Fix issues with mapping ipv4 to ipv6 setups when server is behind proxies with login (#4606)
- Fix issue with v-change-sys-ip-nat with VSFTPD and systems behind NAT (#4591)
- Fix issues with IDN domains and Apache2 and PHP (#4583)
- Improve Owncloud templates (#4572)
- Improve security Quick Install Apps (#457 #4569 #4568 #4567 #4566 #4565 #4564 #4563)
- Add hestia-mail to hestia-users group and create hestia-users group on new install #4540 #4531
- Hide orgin ip of clients when sending email #4662

### Depencies

- Update hestia-nginx to 1.27.0
- Update hestia-php to 8.3.9
- Update Roundcube, Filegator, Snappy mail to the latest version
- Update Quick Installer apps to latest version (#4594)

## [1.8.12] - Service release

### Security

- Restrict hestiamail file permissions (todo should probably have a link here)
- Fix roundcube permissions ( GH-4387 )

## [1.8.11] - Service release

### Features

- PHP 8.3 Support (#4175)
- Add new template with Wordpress XMLRPC Blocked by default (Nignx Only) (#4168)

### Bug fixes

- Minimal change to the way BACKUP_LA_LIMIT is calculated (#4162)
- Change Filegator to 24 hr clock (#4168)
- Confirm before restoring part of backup (#4147)
- Multiple Bugfixes v-import-cpanel (#4150, #4149 #4144 #4139, #4120, #4121 thanks @vipxr)
- Fix an issue with small screens in logs header (#4126)
- Fixed a few bugs due to the permissions changes with hestiamail user
- Updated v-list-sys-users to fix issues with new hestiamail user
- Use -f instead --force=yes (#4097)
- Delay submit in Desktop Safari (#4137)
- Fixed an bug in v-add-backup-host to report inability to connect via sftp (#4119)
- Allow for optional domain directory write permissions #4109 @evonet

## [1.8.10] - Service release

### Bug fixes

- Include missed changes
- Include <https://github.com/hestiacp/hestiacp/blob/main/install/upgrade/manual/secure_php.sh>

## [1.8.9] - Service release

### Security

- Restrict PHP-FPM permissions to a new user to prevent permission escalation to admin or other users [CVE-xxxx-xxxxx](https://huntr.com/bounties/21125f12-64a0-42a3-b218-26b9945a5bc0/)
- Reduce Nginx keepalive_requests to 1000 ([Nginx default](https://www.nginx.com/blog/http-2-rapid-reset-attack-impacting-f5-nginx-products/#http2_max_concurrent_streams)) to limit risks of [CVE-2023-44487](https://www.cve.org/CVERecord?id=CVE-2023-44487)

### Bug fixes

- Fix: removing certificates during apache reload #4053
- Fix: Firehol blacklists #4046
- Fix PHP error + Add option to update WPCLI + Composer #4039
- Update v-add-mail-domain #4027 #4026
- Update MediaWikiSetup.php #4034
- Fix: for v-list-sys-services, pidof command in Debian Buster doesn't support option -d #4022
- Update main.php humanize_usage_size() #4015
- Fix: Prevent the script v-add-sys-roundcube from freezing during Roundcube upgrade #4018
- Fixed an issue with login when 2FA was enabled

### Dependencies

- Update Filegator to 7.9.3
- Update Roundcube to 1.6.4
- Update Snappymail to 2.29.1

## [1.8.8] - Service release

### Security

- Security patch for XSS in Edit server (#4013)

### Bugfixes

- Improve Gitea template with SSL support (#4012 @asessa)
- Restart Nginx / Apache2 when suspending users via Web UI Bulk option (#4007)
- Fix time and date variables in v-user-package (#4008 #sahsanu)
- Prevent users creating DNS records with the ID 0 (#3993)
- Decrease minimal length ipset files to 5. (#3992)
- Add wp-cli to the user .bash_aliases file (#4002)
- default value true to yes for three POLICY_USER directives (#3998)
- Update v-delete-sys-api-ip (#3994)
- Fix v-add-sys-quota and v-delete-sys-quota (#3991)
- Allow up to 13 arguments for the api instead of 9
- Fix an issue with listing overall stats admin user (#4001)

### Dependencies

- Update phpquoteshellarg to 1.1.0
- Update Roundcube to 1.6.9
- Update Blackblaze CLI to 3.10.0
- Update Phppgadmin to 7.4.16

## [1.8.7] - Service release

### Bugfixes

- Fix typo in v-update-whitelabel-logo

## [1.8.6] - Service release

### Features

- Advertise auth only on localhost and TLS connections (#3935)
- Added functionality to reset custom log. (#3952)

### Security

- Security patch for XSS in Edit server (#3946)

### Bugfixes

- Fixed an issue with v-generate-ssl-cert and IDN domains (#3942)
- Add source_conf to the installers
- Fixed White label Descriptions (#3952)
- Update v-change-mail-domain-sslcert (#3920)
- Improve v-list-sys-sshd-port to check custom ssh port (#3922)
- Fixed Open PHPMyAdmin in new Window (#3196)
- Add line breaks SSL Aliases / Allow purge cache via drop down (#3917)
- Clarify Rclone instructions in docs (#3948)

## [1.8.5] - Service release

### Bugfixes

- Fixed an error that could occur when adding a new package (#3883)
- Fixed an issue in `v-list-sys-interfaces` (#3912)
- Minor refactoring of user interface code (#3893)
- Improved shell output of `v-list-web-domain` (#3888, thanks #hudokkow)
- Fixed a bug in `v-delete-sys-ip` on Ubuntu systems (#3894)
- Add user role details to `v-list-users` (#3898)
- Rename "Comment" to "Chain" in Firewall UI to better reflect the fields purpose (#3901)
- Updated translations (#3907)

## [1.8.4] - Service release

### Bugfixes

- Fixed an issue where logs entries would be duplicated when calling return_hash (#3869)
- Modified installer behavior so that firewall rules are only added for necessary services (#3871)
- Minor adjustments to styling and classes (#3843)
- Improved robustness of v-list-sys-themes (#3842)
- Minor updates to v-update-mail-domain-ssl (#3850)
- Changed default PHP-FPM version to 8.2 (#3861)
- Minor updates to v-generate-password-hash (#3874)
- Fixed an issue that would occur during installation if Cloudflare IP address range could not be updated (#3876)
- Fixed multiple PHP warnings and 500 error when mail was not installed (#3841, #3877)

### Dependencies

- Removed typescript from the project for simplicity (#3821)
- Removed PostCSS and move to Lightning CSS (#3820)
- Updated translations (#3878)
- Updated dependency eslint to v8.46.0 (#3881)
- Updated dependency esbuild to v0.18.16 (#3826)
- Updated dependency stylelint to v15.10.2 (#3829)
- Updated dependency chart.js to v4.3.2 (#3866)
- Updated dependency hestiacp/phpquoteshellarg to v1.0.1 (#3827)
- Pinned dependency @fortawesome/fontawesome-free to 6.4.0 (#3862)
- Updated renovate config (#3840)
- Updated all non-major dependencies (#3880)

## [1.8.3] - Service release

- [UI] Fixed an issue where the wrong user type icon was displayed the top menu bar (#3810)
- [UI] Fixed back button links on SSH, API, Logs, and White Label pages (#3811)
- [UI] Fixed "No IPset lists defined" even when lists are defined (#3812)
- [UI] Removed animation effect from login screen (#3822)
- [UI] Fixed an issue where search results were not being returned for all users when logged in as `admin` (#3833)
- [UI] Removed animations from all page loads to improve performance (#3836)
- [UI] Moved debug mode enablement switch to a more logical place (#3838)
- [DNS] Ensure domain is formatted properly with DNSSEC (#3814)
- [API] Added update-dns-record permission to the API (#3819)

## [1.8.2] - Service release

- Added more files to default proxy extensions (#3768)
- Increased width of menu bar dropdowns on mobile (#3765)
- Increased HSTS max-age to 31536000 (#3762)
- Add prompt to `v-update-sys-hestia-git` to install NodeJS if not present (#3779)
- Fixed an issue where `v-update-sys-ip` was not run on boot on Debian systems
- Fixed an issue where the system hostname would lose its FQDN format on reboot when using Proxmox VE containers
- Fixed an issue ith `v-generate-ssl-cert` (#3783)
- Fixed an issue where the port was missing in welcome email (#3784)
- Fixed an issue with the `is_mail_new` function (#3785)
- Fixed an issue where the "Save" button would appear before warning was dismissed when attempting to add a domain or database as admin (#3786)
- Fixed an issue where MySQL 8 could not be installed on Ubuntu (#3788)
- Fixed an issue with TLS connections when using ProFTPD (#3790)
- Fixed an issue where vlan or virtual NIC connections would fail the adapter validity check when adding an IP address (#3797)
- Fixed several PHP 500 errors and warnings in the Control Panel backend (#3789)
- Fixed an issue with v-change-dns-domain-ip and DNS cluster (#3803)
- Update Multiple Quick install apps (#3800 and #3801)
- Updated language translations

## [1.8.1] - Service release

- Fixed Debian 10 not working with IP addresses check
- Fixed Exim4 update config via patch was unreliable added few safety checks and add notice if failed.
- Fixed hestia-nginx not loading with custom port

## [1.8.0] - Feature / Major release

### Notes

- Dropped support for Ubuntu 18.04 Bionic due to EOL Please upgrade to 20.04 or 22.04.
- Custom nginx templates require some changes due to deprecated http2 parameter for the listen directive by Nginx 1.25.1 (#3684, #3704) and 0-RRT Protection introduced in (#3692)
- Dropped support for Rainloop and replaced by Snappymail (#3590)

### Features

- Added support for Debian 12 (#3661)

- Enhanced and Optimized TLS (#3555 @myrevery)
- TLS 1.3 0-RTT with replay protection (#3692 @myrevery)
- Add support for SRS in Exim >= 4.9.5 (#3197 @henri-hulski)
- White label support and refactor translations (#3441 #3572)
- Improve user notifications UI (#3709)
- Continue work on UI improvements (#3700, #3693, #3691, #3685, #3682, #3680, #3672, #3668, #3662, #3659, #3651, #3634, #3629, #3628, #3619, #3615, #3608, #3606, #3602, #3600, #3598)
- Allow option to enable/disable backup suspended users (#3696 )
- Feature: v-dump-database (#3644)
- Allow users to create own document error / skeleton and do not overwrite them with updating (#3622)
- Consistent overlay styles (#3617)
- Integrate SnappyMail (#3590)
- Allow sorting on package name (#3726)
- Add templates for yourls (#3755 @ediazmurillo)

### Bugfixes

- Fix: DNS cluster expected return code instead of string (#3706)
- Resolve #3684 Process "http2" directive for NGINX (#3704 @myrevery)
- Upload hestiacp.pot file directly to Crowdin (#3702)
- Refactor add ns buttons (#3701)
- Remove \r chars from VestaCP cron.conf (#3708 @maunklana)
- Unable to edit password domain smtp relay (#3690)
- Fix: #3687 Improve check if alias already exists (#3689)
- Fixed bug in v-update-sys-ip when multiple interfaces / ip addresses are available (#3688)
- Prevent empty ns1 / ns2 to be used (#3683)
- Reload web server up on deleting web domain. #3705
- Fix sed for installing sieve (#3679)
- Tidy development docs (#3677)
- Fix typo in v-delete-sys-filemanager (#3678)
- Improve DNS SEC Public key information display (#3676)
- Switch from Yarn v3 to npm (#3675)
- Fix #3643: SOA updating on rebuild command from main server (#3660)
- Fix: Import CPanel when account email is non existing (#3670 #3667)
- Fix: Import CPanel when mail domain and or web domain already exists (#3670 #3667)
- Normalize v-add-user-package input (#3671 #3669)
- smtputf8_advertise_hosts is not supported by deb10 (#3652)
- fix Gitea template (#3650 @asessa)
- Fix issue with redirect to subfolder (#3623)
- Replace current nginx template with suspended template (#3641)
- Fix issue with duplicated phpmyadmin-auth blocks in jail.local (#3642)
- Fix error in rebuild script (#3639)
- Fix bug in syshealth script
- Refactor and fixes for handling system IP/Interfaces (#3605 @myrevery)
- Fix #3496 Fix issue with Sieve and SMTP relay (#3581 @s4069b)
- Add jail rule for incorrect for phpmyadmin (#3596)
- Fix #3599 Disable SMTPUTF8 (#3603)
- Fix content shift on stats row hover (#3614)
- Fix issue with checkbox is not selected port return "no" (#3616)
- Encode passwords in emails send (#3566)
- Add support for PHPmyAdmin SSO support for Mysql 8 (#3539)
- add alias to wp-cli to the user's .bashrc and fix error handling. (#3569 @aosmichenko)
- Simplify suspend/unsuspend dialog translations (#3565)
- Tidy notifications copy (#3561)
- Predefined Ipset lists not loading #3552 (#3557)
- Minor UI fixes to server console output (#3556 @myrevery)
- Fix #3745 Translations not loading (#3746)
- Make IPset visible when F2B is not installed (#3750)
- Fix: #3729 Missing robots.txt get redirected to WP (#3739) / Add WordPress Multisite subdir support (#3741 @hudokkow )
- Fix issue with Global SMTP settings not updating (#3730)
- Add phpbb Nginx template (#3732 #3731 @xchwarze)
- Update Nextcloud template (#3725 @Steveorevo)
- Fix php error when DNS disabled when updating user (#3726)
- Fix: #3712 Unable to restore domain with custom doc root (#3726)
- Add BIENNIALLY & TRIENNIALLY stats on TaskMonitor (#3721 @caos30)

### Dependencies

- Update hestia-php to 8.2.7
- Update hestia-nginx to 1.25.1
- Update Quick install apps versions

## [1.7.8] - Service releae

### Bugfixes

- Fix reflected XXS in debug panel when debug mode was enabled or the user accessed directly the debug panel template. [CVE-2023-3479](https://nvd.nist.gov/vuln/detail/CVE-2023-3479)

## [1.7.7] - Service release

### Bugfixes

- Fix #3588: Delete issue DNS record (#3589)
- Tidy notifications copy (#3561)
- Predefined ipset lists not loading #3552 (#3557)

## [1.7.6] - Service release

### Bugfixes

- Fixed Error message "deleted" before shown due to register_shutdown_function (#3548 #3547)
- Fixed an in issue in humanize_usage_size with number format (#3546 #3547)
- Fixed rounding issue with humanize_usage_measure (#3540 #3541)

## [1.7.5] - Service release

### Bugfixes

- Fix issue with install MariaDB (#3543)
- Add a check to prevent ARM64 installs with Mysql8 on Debian (#3543)

## [1.7.4] - Service release

### Features

- Build JS/CSS Theme on release (#3525)
- Refactor away jQuery

### Bugfixes

- Remove Font Awesome "brands" usage (#3535)
- Make uft8mb4 default charset for databases (#3534)
- Remove extra slash in SSO url (#3533)
- Improve Quick Install App password input (#3530)
- Kill OpenSSL server if its already running before validating SSL certificate (#3505)
- Improve redirect behaviour (#3503)
- Fix: PMA SSO for cp panel template (#3493)
- Fix: Bug in sftp backup (#3489)
- Improve Quick Install App password input (#3530)
- Refactor away on click usage on login pages (#3526)
- Refactor Add/Edit Firewall Rule JS (#3522)
- Build Alpine.js bundle (#3521)
- Improve charts JS (#3519)
- Show spinner when confirming dialog action (#3517)
- Refactor Edit Web JS/remove jQuery (#3513)
- Refactor Add/Edit Database JS (#3511)
- UI updates (#3510)
- Refactor JS (#3508)
- Fix #3318 Remove: decrepitation warning MariaDB (#3465)
- Fix: 3514 Fix UI not matching true value (#3515)
- Refactor form submit JS (#3502)
- Refactor JS (#3500)
- Refactor unlimited input JS (#3495)
- Tidy JS (#3492)
- IPV6 compatible prevent CSRF (#3491)
- Rewrite statistics UI mobile-first (#3490)
- Refactor JS (#3488)
- Add Quota info to the user list (#3487)
- Minor UI updates (#3485)
- Dynamically load Chart.js bundle (#3480)
- Refactor JS to use ES modules (#3476)

## [1.7.3] - Service release

### Features

- Re-implement RRD charts in Chart.js (#3452)
- Add JS/CSS build script (#3471)

### Dependencies

- Update hestia-php to 8.2.5
- Update hestia-nginx to 1.23.4

### Bugfixes

- Fix: named command warning (#3447 @neto737)
- Fix: Include Cloudflare IPS during install (#3449 #3448)
- Fix: Bug in upgrade_phppgadmin preventing folder from being created when not exists (#3450)
- Add warnings to php-fpm templates (#3450)
- Exim: Never show HELO for authenticated users (#3462 @myvesta)
- Misleading title "Error" on popup notification when creating manual backup (#3460 #3461)
- Fix: Do not add a trailing . on DNSKEY #3458
- Fix toolbar spacing on mobile in some scenarios e.g. Backups page (#3460)
- Fix: Users can not create a new DNS domain (#3451)
- Fix: Error message containing html are encode twice (#3473)
- Fix button width regression (#3474)
- Remove opacity from modal background (#3460)
- Refactor add/remove name server javascript (#3468)
- Refactor "Unlimited" inputs (#3464)
- Refactor password strength JS (#3459)

## [1.7.2] - Service release

### Note

- HestiaCP 1.7.2 fixes an issue with downloading certificates from Let's Encrypt due to the implementation of asynchronous requests which will go live on 10th April 2023. Please update your server before this date to ensure compatibility with Let's Encrypt.

### Bugfixes

- Fixed an issue php after default php version change (#3145 #3414)
- Fixed importing Add Domains v-import-cpanel (#3242 @adion-gorani)
- Fixed and issue with DNSSSEC check if DNSEC is available (#3430)
- Fixed an issue with v-add-web-domain-redirection (#3438 #3440)
- Remove leading and trailing spaces on a domain (#3439 #3440)
- Fixed an issue with domain.com:/public_html in v-backup-users (#3434)
- Fix and issue with custom webmail clients (#3419 #3420)
- Refine :focus styles (#3432)
- Replace jQuery UI tabs with vanilla JS (#3413)
- Reduce amount of animation styles (#3418)
- Minor UI updates (#3425)
- Fixed an issue with v-suspend-dns-record still loading after being disabled (#3441 @setiseta)
- Replace jQuery UI dialogs with <dialog> (#3401)
- Fixed an issue SSL not found + php error on login page. (#3404)

## [1.7.1] - Service release

### Bugfixes

- Fixed an issue with wildcard overruling webmail.domain.com config in Apache2 (#3400 #1631)
- Removed delete button edit user page (#3997)
- Fixed an issue with serial not increasing (#3396)
- Fixed an issue with new hestia-zone sync and servers behind NAT or with multiple IPs (#3388 #3396)
- Remove option to enable DNSSEC when DNSSEC is not supported (#3372 #3396)
- Fix toolbar items on locales with long words (#3380 #3395)
- Only count \*.tar files in rotate routine (#3393 #3385)
- Fixed broken upgrade_mariadb.sh (#3391 @myrevery)
- Improve add_firewall_ipset.php (#3390 @myrevery)
- Update Path change of IPset blacklist.sh (#3389 @myrevery)
- Improve upgrade script Cloudflare ips (#3388 @myrevery)
- Update supported message hst-install.sh (#3377 @shizualand)
- Fixed an issue with adding own ssl certificated to website config (#3374 #3371)
- Fixed javascript logic edit mail domains (#3373)
- Add required attribute to login forms (#3376)

## [1.7.0] - Feature / Major release

### Note

- Debian 9 (Stretch) is no longer supported as it has reached end-of-life status.
- Basic mobile support has been added in this release. This is early stages and we'd very much appreciate your feedback and any reporting of bugs, to further improve the mobile experience

### Features

- Added basic support for mobile devices (#3166, #3141, #3142, #3157, #3155, #3120, and many more)
- Added DNSSEC support for DNS domains (#2938)
- Added support for MySQL 8 (for new installations) (#xxxx @xxxxx)
- Added support for exim rate limiting in package definitions (#2920)
- Added support for ssh keys for SFTP backups (#2906)
- Added Rclone support for backups to AWS, Cloudfare and [+40 other storage systems](https://rclone.org/overview/) (#2928)
- Added support for importing Cpanel backups (#3238, #3232 @skamasle)
- Added support for folder wildcards in backup exclusions (#2338 @youradds)
- Added Nginx template for Mautic (#3192 3188 @youradds)
- Added alias for composer (#3070)
- Updated PhpPgAdmin and with support for PostgreSQL 15 (<https://github.com/hestiacp/phppgadmin>)
- Upgrade MariaDB to 10.11 (#3305)
- Add Quick installer for Flarum (#3342 and #3298 @Steveorevo)
- Enable UTF8MB4 on default for Mysql (#3337 #1882)
- Update Cloudflare ip adresses on each update (#3338 #2575)

### Bugfixes

- Make .yaml files editable in the file manager (#3200 @BelleNottelling)
- Fixed an issue with search not supporting user impersonation. (#3208 #3199)
- Prevent users from renaming directories in /home/user/web/ (#3211)
- Allow special characters for user account "Name" field (#3210)
- Prevent usernames from containing special characters (#3220 #3213)
- Increase DKIM length (#3218)
- Improve password meter CSS (#3221)
- Improve restart behaviour v-update-letsencrypt-ssl (#3231)
- Fix order of applied patches on upgrade (#3239)
- Improve upgrade behaviour for Roundcube and Filegator (#3237 #3236)
- Allow <ClientName@domain.com> for login via Dovecot/Email (#3024)
- Return a proper error code when unable to connect via API (#3235 #3169)
- Synchronise $BIN and $HESTIA/BIN (#2185 @Steveorevo)
- Block usage of unlimited backups (#3181)
- Update paths /var/run/ to /run (#3159)
- Update PHP versions on various Quick Install apps (#3167 #3149 @dadangnh)
- Update Media Wiki version to 1.39.1 (#3168 @kizule)
- Replace custom HTTPS socket code with libcurl (#3160)
- Add config to avoid restarting daemons on error (#3183 @joeakun)
- Fixed an issue with default template and Quick App installer #3133
- Generalise password reset instructions. #3112
- Allow .tpl files to be editable in File Manager (#3148 @neto737)
- Fixed an issue where domain alias was not being created for domains with two-tier TLD's (such as .co.uk) (#3030)
- Fix/sync issues with existing domains (#3028)
- Fixed an issue Unable to create tmp directory (#3019)
- Fixed an issue with mysqld-iptables in Fail2Ban (#3025)
- Fixed an issue with Logrotate and Awstats (#3297)
- Added Google Public DNS as a secondary resolver to nginx configuration
- Fixed an issue with Proftpd and passive mode external IP (#3266)
- Improve IPv6 handling in v-change-sys-port (#3276 @asmcc)
- Set the correct conflicts for hestia-php on Ubuntu 22.04
- Fixed an issue with erroneous deleting $domain.\* instead of $domain.pem (#3221)
- Fixed an issue with domain redirect and idn2 domains (#3323 #3325)
- Fixed an issue in Dokuwiki due to changing repository owner (#3327)
- Fixed an issue with B2 and changing access keys
- Fixed an issue with Drupal install via Quick installer (#3353 #3352)
- Fixed issues with default state jQuery UI modals (#3344)
- Fixed an issue with login with passwords that contains a - or -- on the first character (#3365 #3354)
- Add option to disable ip check (#3365)
- Replace sdocroot with docroot in default.tpl for Apache2 / PHP-FPM setups (#3360)

### Dependencies

- Updated hestia-nginx to 1.23.3
- Updated hestia-php to 8.2.4
- Update OpenSSL to 3.1.0
- Updated Roundcube to 1.6.1
- Updated Filegator to 7.9.2
- Updated phpMyAdmin to 5.2.21
- Updated phpPgAdmin to 7.3.14-hestiacp
- Update MediaWiki to 1.39.2
- Update Prestashop to 8.0.1
- Update TwoFactorAuth to 2.0.0

## [1.6.14] - Service release

## Bugfixes

- Improve firewall rules cleanup #3135 @myrevery
- Reverted changes to v-add-web-php as php8.2-imagick is now available
- Fixed an issue with editing timezone in when editing a server (#3127)
- Fixed an issue with hostname during install
- Fixed an issue with WordPress installer not working properly (#3129)

### Dependencies

- Update MediaWiki to 1.39.0

## [1.6.13] - Service release

### Bugfixes

- Fix issue with php8.2-imagick not available
- Fixed an issue with Letsnecrypt and no mail features enabled (#2930 #2931)

## [1.6.12] - Service release

### Features

- Add support for PHP 8.2

### Bugfixes

- Fixed an issue with Europe/Kyiv not existing in Debian / Ubuntu causing issues with saving (#3031 #2971)
- Fixed an issue with v-backup-user loop when the user is unable to create a temp folder or not enough space (#2923 #3019)
- Fixed an issue with restarting with via api (#1236 #30230)
- Fixed an issue with \*.co.uk and similar domains that does not create a www alias (#1750 and #3030)
- Fixed an issue with enabling mysqld-iptables (#3035 @Krzysiek86 @neto737)
- Add an alias for composer in bash_aliases (#3070 @madito)
- Fix issues with multiple ips and hostname in installers (#3068)
- Fixed an issue with Nginx + Apache2 settup and clearing proxy cache (#3060)
- Update WordPress to avoid caching of WordPress Rest API (#3069 @niktest)
- Fixed an issue with firewall and IPset tables shorter then 10 records (#3110 @myrevery)
- Delete rrd database on deleting database host
- Fixed an issue where a user was unable to change database user #3051
- Fixed an issue with unsuspend database user permissions (remote) #3011 #3046
- Fixed an issue with v-add-domain and package doesn't allow mail / web or DNS domains

### Dependencies

- Update PHPmailer to 6.7.1

## [1.6.11] - Service release

### Important

A bug in v-update-sys-hestia caused auto update to be not working. Please run: `apt update && apt upgrade`

### Security

- Fix issues with session timeout and filemnanger (#3004)

### Bugfixes

- Fixed an issue in auto update script for HestiaCP (#2967)
- Fixed an issue in download ssl certificate in Firefox (#2979)
- Resolve issue with idn domains and redirect (#2988)
- Update Ipverse url for United Kingdom (#2962)
- Fixed an issue with icons disapearing when viewing system logs
- Fixd issue with unlimeted quota button on edit mail account

### Dependencies

- Update Rainloop to 1.17.0 (#2957)
- Update Zlib to 1.2.13
- Update hestia-nginx to 1.23.2
- Update hestia-php to 8.1.12
- Update OpenSSL to 3.0.7
- Update Filegator to 7.8.7

## [1.6.10] - Service release

### Security

- Delete temp files after password has been verified (#2958)

### Dependencies

- Update Filegator to 7.8.3
- Update PHPmailer to 6.6.5

## [1.6.9] - Service release

- Fixed an issue when Installing Wordpress in a non english locale (#2788 #2818)
- Reload Nginx on purging fast cgi cache (#2925)
- Update max number of chars allowed for name (#2924)
- Fixed few small issues with Lets Encypt for hostname (#2922)
- Fixed few issues with Quick installers (#2921)
- Fixed an issue with v-change-web-domain-name
- Update sync-dns-cluster role to run v-delete-dns-domain (#2943)
- Fixed issue with connection with sftp server running FreeBSD (#2950 @gdarko)
- Add support for Kurdish Sorani (#2945 @qezwan)
- Small improvements in syntax for v-add-remote-dns-host (#2951)
- Check if email is valid for PHPMailer (#2944)

### Dependencies

- Update Dokuwiki to stable_2022-07-31a
- Update Opencart to 4.0.1.11
- Update Prestashop to 1.7.8.7
- Update Jquery on login pages to 3.6.1 (#2932 @4183r)
- Update hestia-php to 8.1.11

## [1.6.8] - Service release

### Features

- Update default php settings (#2849 #2635)

### Security

- Fix issue in is_hestia_package (#2889)

### Bugfixes

- Force update composer to v2 instead of v1 when no version is provided (#2839 #2777)
- Fixed an issue with v-change-web-domain-owner and mail only domains (#2840, #2841)
- Grey out phpmyadmin buttons + add link to docs.hestiacp.com for support (#2843)
- Block the use of CNAME records on @ or root records DNS domain (#2838, #2842)
- Code clean up and remove unused tests and templates (#2829 and #2831)
- Fixed an issue where no password was send when a user create a new mail account (#2819 #2815)
- Fixed an issue with Proxmox LXC and hostnames (#2819 #2048)
- Improve new email account email send to the user (#2819 #1417)
- Improve buffers nginx.conf (#2796)
- Improve Letsencrypt error message (#1804 #2854)
- Fixed an issue with error logs failed login attempts (#2853)
- Fixed and issue with saving UTC time zone in Edit server (#2851 #2853)
- Fixed an issue with sshd not running but still showing up in rare cases (#2850 @manuelserol)
- Improve error message "Domain already exists" when the "main" domain belonged to an other user (#2848 #2771)
- Fixed an issue with v-delete-letsencrypt not working when deleting a mail domains SSL (#2878)
- Fixed an issue with storing B2 Secret key in b2.conf (#2843)
- Update jail.local with example to add ignore ip (#2856)
- Add use_temp_path to no to slightly speedup caching (#2855)
- Fix small php errors (#2863 #2857 @YacineSahli)
- Fixed an issue API and DNS cluster over multiple servers where username/password and hash where mixed (#2888)
- Add option to use custom javascript code (#2747)
- Add "v-rebuild-dns-domains" to sync-dns-cluster options
- Fixed an issue with Yescript and api (#2899)
- Add logrotate config for Roundcube (#2868 #2904)
- Fixed an issue with session files in /tmp/ folder caused by /web/inc/mail-wrapper.php (#2904)
- Fixed an issue with v-restore-user does not delete old database before restoring causing new tables to remain exists (#2911 #2909)
- Fixed an issue with deleting mail account does not remove ratelimit for that email account (#2905 #2903)

### Enhancements

- Clean up / decrease size of images, favicons, javascript, css and html (#2879, #2871, #2872, #2873, #2884, #2883, #2879 @AlecRust)

### Dependencies

- Update hestia-nginx to 1.23.1
- Update hestia-php to 8.1.9
- Update animate.js to 3.0.2 (#2879)
- Update normalize.css to 3.0.3 (#2875)
- Update jQuery to 3.6.1 (#2885)
- Update MediaWiki to 1.38.2
- Update PHPmailer to 6.6.4
- Update Blackblaze CLI to 3.5.0

## [1.6.7] - Service release

### Bugfixes

- Fixed an issue with upgrade script Roundcube that caused issues with upgrade of new installs
- Fixed an bug with DNS templates #2827
- Update v-update-sys-hestia-git

## [1.6.6] - Service release

### Bugfixes

- Update DNS templates with CNAME for ftp, www and webmail (#2808)
- Fix name server A record validation error (#2807)
- Fixed issue with renaming domains and config files not properly removed (#2803)
- Add loading indicator after clicking save button (#2740)
- Improve hostname detection in mail-wrapper (#2805 @clarkchentw)

### Security

- Fixed an vulnerability in v-add-web-domain-redirect (CVE-2022-2636)
- Fixed an vulnerability in Ubuntu that can lead in privilege escalation for admin to root user (CVE-2022-2626)

### Dependencies

- Update Roundcube to 1.6.0
- Update Dokuwiki to "2022-07-31" Igor (#2811)

## [1.6.5] - Service release

### Bugfixes

- Add missing translation strings (#2778 @myrevery)
- Add check if folder exists in v-change-web-domain-docroot (#2778)

### Security

- Improve random bytes generator (#2774)
- Don't allow /inc/2fa/secret.php called from the web browser directly (#2784 @mayappear)
- Improve CSRF Origin Check Bypass (#2785 @mayappear)
- Fix vulnerability in Dokuwiki Quick Install App @redstarp2 (CVE-2022-2550)
- Fixed an issue where custom ports where not saved on restart fail2ban service making Hestia login screen vulnerable for brute force

### Dependencies

- Update Filegator to 7.8.2

## [1.6.4] - Service release

### Bugfixes

- Fixed an issue with downloading log files ()
- Fixed an issue with installing Quick Installers (#2762, #2760, @divinity76)
- Fixed an issue with Apache Access / Awstats logs IP after using v-update-sys-ip (#2759 @adion-gorani)

## [1.6.3] - Service release

### Features

- Add additional support for bcrypt for mail passwords (#2752 @divinity76)

### Enhancements

- Simplify md5crypt on reset form email (#2751 @divinity76)
- Use secure RNG to generate passwords (#2726)
- Add twig support filemanger (#2714, @anvme)

### Bugfixes

- Fixed an issue with restart Apache2 and Nginx after v-update-letsencrypt (#2748, #2563, #2744, #2677)
- Prevent transversing path in Quick installer apps (#2742)
- Avoid out of memory serving large logfiles (#2741, #2736, @divinity76
- Improve passwords loading in password_valid (#2739)
- Use secure RNG to generate passwords (#2726)
- Utilise entire alphabet for random string (#2735 @Shadowfied)
- Don't use hosts_try_fastopen in Exim for Gmail / Google hostnames
- Add check if Sieve is already installed (#2719 #manuelserol)
- Allow PHP templates to be selected in Quick installer apps (#2713, #2711, #2690)
- Small changes to translation strings (#2700 @V4M0N0S)
- Rate limit in email address blank in UI (saved correct in limits) (#2710, #2707)
- Fixed a bug in Settings sites where always websites got rebuild on save (#2705, #2710)
- Fixed a bug in Weblog where the session got incorrectly reset as admin user (#2710)
- Prevent v-add-web-php to be used for non fpm installs (#2753)
- Update translations (#2750)
- Chmod o+x .ssh folder when creating file manager ssh key (#2755)

### Dependencies

- Update hestia-php to 8.1.8
  - Update disable_functions list php.ini for hestia-php (#2746, #2741)

## [1.6.2] - Service release

- Fixed an issue with rate limits in Exim4 and make it more bullet proof (#2703)
- Fixed an issue with system-filter not properly loaded in Exim4 for Exim 4.94 and Ugrades from 1.5.x

## [1.6.1] - Service release

### Bugfixes

- Fixed an issue with rate limit and alias domains (#2676, #2666)
- Fixed an issue with reject spam option (#2687, #2864)
- Fixed an issue in the installer when sieve is enabled (#2675, #2668)
- Fixed an issue with File manager in development mode (#2682 #2644)
- Fixed multiple small in templates (#2659 @ledoktre, #2680, #2671, #2679, #2670, #2681, #2699)
- Fixed add second check if DNS resolving fails (#2678)
- Fixed an issue where v-change-sys-hostname does not update host file (#2688 #2683)
- Fixed an issue with IDN conversions not working on new server installs (#2692 @wojsmol)

### Enhancements

- Improve restart behaviour php-fpm
- Improve updating process to make it faster.
- Removed outdated / never used test scripts (#2685)

### Dependencies

- Update hestia-nginx to 1.23.0
- Update PHPmailer to 6.6.3
- Update Roundcube to 1.5.3

## [1.6.0] - Major Release (Feature / Quality Update)

### Important Notes

- Added support for Ubuntu 22.04 Jammy. If you planning to upgrade your server from Ubuntu 20.04 or 18.04 to Ubuntu 22.04 read the instruction carefully!
- Issues with Ubuntu and Netplan and additional ip addresses has been discovered if this is the case for your setup please check if Netplan configuration is correct.
- Due to know security issues with Rainloop [CVE-2022-29360](https://blog.sonarsource.com/rainloop-emails-at-risk-due-to-code-flaw/) and the lack of updates from there side we are planning to update / replace Rainloop with [Snappymail](https://github.com/the-djmaze/snappymail). How ever minor changes are needed to the release of Snappymail. The required changes have been made however we are waiting for for the final release of 2.16.4
- Added support for Yescrypt and ARGON2ID for storing passwords of the users / email accounts password. If you encounter any issues (after importing a backup) with logging change the user / email account password and it will solve any issues.

### Deprecated

- Dropped support for Debian 9 for new installs (#2537)
- Dropped support for RSSH on Ubuntu 18.04 on install (#2537)
- Dropped support for TLS1.1 and older for Dovecot (#2012 and #2538)

### Features

- Added support for Ubuntu 22.04 Jammy (#2537 #2489)
- Added support Exim rate limits for email accounts via UI (#2225 and #2523 @madito)
- Added support to delete spam when reaching certain threshold (#2206 and #2200 @madito)
- Added support to send mail to an unauthenticated SMTP relay (#2441 @clarkchentw)
- Replace default MD5 encoding with ARGON2ID for Debian 10 and Ubuntu 20.04 and higher (#2421 @stsimb)
- Added support for Yescrypt (#2235 / #2499)
- Upgrade backend to PHP8.1 due to compatibility issues Jammy (#2515)
- Introduce new api allowing users to use certain commands over API (#2535 and #1333)
- Allow "Purge" cache button visible on templates with the name cacheing-your-template-name (#2526 #2530)
- Add hooks to hestia-nginx and hestia-php (#2440)
- Update DNS cluster to support new API system (#2587)

### Bugfixes

- Fixed an issue where --hostname and --email did not validated when using --interactive no (#2532 #2531)
- Fixed an issue with the detection if MariaDB 10.7 was running (#2536 @gOOvER)
- Fixed an issue with downloading a backup as a standard user (#2524 #2525)
- Remove duplicated package installer (#2520 @rfzh1996)
- Fixed an issue with "Do not allow user to login" checkbox sync up with real settings (#2507 #2513)
- Fixed an issue where deleting a suspended users did not decrease the suspended user counter (#2504 #2531)
- Fixed an issue where domain with redirect enabled was not able to "request" Lets encrypt ssl (#2514 #2176)
- Add an notice when using Blackblaze on a ARM64 based server (#2394 @zedpr0)
- Add rsyslog as a dependency (#2505)
- Fixed an issue when a user import a backup a let's encrypt cronjob was not created on default. (#2498 @NickCoolii)
- Add missing translation conversions in backup list (#2501)
- Update example in v-add-web-domain-backend (#2500 gingerbeardman)
- Update example in v-add-letsencrypt-domain (#2442)
- Fixed an issue in configure-server-smtp.sh by loading /etc/hestiacp/hestia.conf (#2488)
- Update Cloudflare ips in nginx.conf (#2542 @clarkchentw)
- Remove duplicate code in Ubuntu installer (#2542 @clarkchentw)
- Fixed an issue in Nginx + Apache2 mail "disabled" template. Causing users unable to request an valid ssl certificate (#2550 #2549)
- Fixed an issue with "Reject spam" option not working (#2551 #2545)
- Fixed an issue with Editing / Adding DNS records (#2546, #2547, #2548 @DunoCZ)
- Fixed an issue with TXT records longer then 255 characters (#2559)
- Fixed an issue with wp-cli permission denied and allow wp-cli to be run in v-run-cmd command (#2562 and #2565)
- Fixed an issue with apt-get install output not written to install log (#2585)
- Fixed multiple issues with improved Quick installer app for Wordpress (#2583)
- Changes in upstream package caused phpMyAdmin Single Sign on feature to break (#2591)
- Fixed issues with DNS cluster and the new API (#2587)
- Fixed an issue where PHPpgAdmin config files was not renamed to .inc for Apache2 setups (#2592)
- Startup Fail2ban on boot for Ubuntu 22.04 (#2596 #2594)
- Fixed issue with duplicate config value (#2640 @Kujoe and #2605 #2610 )
- Fixed an issue with change password function for webmail clients
- Fixed multiple issues with Quick install apps in general (#2444, #1092, #2638)
- Fixed an issue with memory usage graph and non english locale (#2643 #2540)
- Fixed an issue with incorrect download path ftp backup (#2636 @cloudyhostcom)
- Add php8.1 in v-run-cli-cmd (#2630 @gOOvER)
- Fixed multiple issues with wildcard and Letsencrypt (#2627, #2626, #2624, #2623)
- Fixed multiple issues in v-change-domain-owner (#2618, #2617, #1864)
- Fixed an issue with MariadDB 10.8 detection (#2616)
- Fixed an issue with netplan and additional ip addresses (#2612)
- Removed MariaDB repo form Ubuntu 22.04 install
- Don not install Roundcube dependencies if Roundcube is missing while installing sieve.
- Remove duplicated code in v-add-web-domain-ssl

### Dependencies

- Update hestia-nginx to 1.22.0
  - Update OpenSSL to 3.0.3
  - Update zlib to 1.2.12
  - Update PCRE to 10.40
- Update hestia-php to 8.1.7
- Updated phpMyAdmin to 5.2.0 (<https://www.phpmyadmin.net/files/5.2.0/>)
- Update Filegator to 7.8.1
- Update PHPmailer to 6.6.2
- Update composer dependencies

## [1.5.15] - Service release

### Bugfixes

- Fixed an issue with wildcard DNS records

### Dependencies

- Update phpMyAdmin to 5.1.4 (<https://www.phpmyadmin.net/files/5.1.4/>) (#2529)

## [1.5.14] - Service release

### Bugfixes

- Fixed an issue with login with ipv6 (#2564)
- Fixed an issue with dns records containing an . (#2559)

## [1.5.13] - Service release

### Bugfixes

- Fixed an issue in add / change dns record via GUI. (#2557)

## [1.5.12] - Service release

### Bugfixes

- Fixed vulnerability with Sed [CVE-2022-1509](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-1509)
- Remove localhost exception for invalidating sessions [SSD disclosure](https://ssd-disclosure.com/ssd-advisory-vestacp-multiple-vulnerabilities/)

## [1.5.11] - Service release

### Bugfixes

- Fixed an issue where Hestia port change did not update chain for fail2ban (#2465)
- Fixed permission issues with /var/log/roundcube (#2466)
- Fixed multiple issues in UI (#2464)
- Allow v-change-user-template update backend templates (#2475)
- Update composer dependencies (#2458 #2459)
- Fixed an XSS vulnerability in "Edit" server page. (#2471) [CVE-2022-0986](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0986)
- Fixed an issue with caching templates and internal redirects (#2482)

## [1.5.10] - Service release

### Bugfixes

- Fixed an issue where webmail client options were not displayed in the Web UI (#2445)
- Fixed an issue where users where not able to create an backup. (#2448 / #2449)
- Fixed an issue where saving server settings could fail due to an incorrect PHP version check on mod-php servers (#2451)
- Fixed an issue where MariaDB installations were broken when performing a clean install of HestiaCP v1.5.9 (#2452 | 2446)
- Fixed recently discovered XSS vulnerabilities (#2453) [CVE-2022-0838](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0838)

## [1.5.9] - Service release

### Bugfixes

- Fixed multiple XSS vulnerabilities in the web user interface. [CVE-2022-0752](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0752) / [CVE-2022-0753](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-0753)
- Fixed an issues with mariadb.sys user didn't work properly on MariaDB 10.6.x installs #2427
- Change ipverse.net urls to new format hosted on Github #2429 and forum
- Allow PTR to be used on domain.com

### Dependencies

- Update PHPMailer to 6.6.0 (<https://github.com/PHPMailer/PHPMailer/releases/tag/v6.6.0>)
- Update Filegator to 7.7.2 (<https://github.com/filegator/filegator/releases/tag/v7.7.2>)

## [1.5.8] - Service release

### Features

- No new features has been introduced

### Bugfixes

- Fixed an issue where SFTP jail was not enabled correctly for additional FTP accounts #2403
- Fixed an issue in the installer where the "Press any key to continue" prompt only responded to the Enter key #2398
- Fixed an issue where list sort order preference variable wasn't saved properly #2391
- Fixed an issue with inconsistent behaviour in mail account settings information dialog #2392
- Fixed an issue where .gnupg folder in /root/ had the wrong permissions set.
- Fixed an issue where users were being redirected to login page when visiting /reset/ endpoint #2401
- Fixed an issue where deleting sftp jail did not revert back permissions of said user. #2143
- Fixed an issue where "REDIRECT" variable wasn't cleared correctly causing other sites to redirect to the domain after v-update-letsencrypt-ssl
- Changed repository url MariaDB for new installs to <https://wdlm.mariadb.com/repo/mariadb-server>

### Dependencies

- Update phpMyAdmin to 5.1.3 (<https://github.com/phpmyadmin/phpmyadmin/releases/tag/RELEASE_5_1_3>)

## [1.5.7] - Service release

### Bugfixes

- Fixed an issue with apt update and public key missing

If you have to following error

```bash
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY A189E93654F0B0E5
```

Follow the following instructions

```bash
rm /usr/share/keyrings/hestia-keyring.gpg
mkdir /root/.gnupg/
gpg --no-default-keyring --keyring /usr/share/keyrings/hestia-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys A189E93654F0B0E5
```

After that run apt update && apt upgrade

## [1.5.6] - Service release

### Bugfixes

- Fixed an issue with the installer. system.pkg didn't allow for a Web alias #2381
- Fixed an issue with upgrade script causing command to to be executed (<https://forum.hestiacp.com/t/upgrading-to-1-5-5-error-line/5449/3>)

## [1.5.5] - Service release

### Features

- Improve default php-fpm.conf files. (#2318, #2343)
- Notify user when a suspended user tries to login (#2310, #2345)
- Allow setting default web install templates for Quick install (#2344) (<https://github.com/hestiacp/hestia-quick-install>)
- Improve security how apt keys are downloaded #2299 (<https://blog.cloudflare.com/dont-use-apt-key/>)
- Allow users to set system php version in Web GUI (#2357)
- Added a link to the firewall in list services (#2371) @fra81

### Changes

- Modify template warning #2346
- Removed 127.0.0.1 from the default accepted ip list api. (#2325)
- Update translations

### Bugfixes

- Update CSS to prevent wrapping in email info box (#2353) @chriscapisce
- Remove unwanted debug information regarding PhpMyAdmin SSO causing emails to be send to administrator
- Allow the use of 8 name servers for DNS templates (Gmail, Zoho and Office 365) (#2369, #2370)
- Fixed an issue where databases where not able to backup if it required custom settings
- Allow users to edit default.pkg again. On new installs the default admin user will get assigned a new system.pkg (#2365)
- Disable enabling PMA SSO when Api was disabled + Added link to FAQ for frequently asked questions. (#2365)
- Remove error_reporting(null) and allow all errors to be logged in /var/log/hestia/nginx-error.log (#2365)
- Fixed an issue where value "Allow suspended wasn't saved" (#2356, #2355)
- Fixed and issue where AUTH_USER and AUTH_HASH was not present and there for during rebuild caused issues with Nginx (#2350, #2355)

### Dependencies

- Update PHPmyadmin to 5.1.2 (<https://www.phpmyadmin.net/files/5.1.2/>)
- Update Filegator to 7.7.1 (<https://github.com/filegator/filegator/releases/tag/v7.7.1>)
- Update B2CLI to 3.2.0 (<https://github.com/Backblaze/B2_Command_Line_Tool/releases/tag/v3.2.0>) (#2349) @ptrinh

## [1.5.4] - Service release

### Features

### Bugfixes

- Fixed an issue with v-add-sys-phpmailer not updating properly (#2336)
- Fixed an issue where users where not able to download backups via UI (#2335)
- Fixed an issue where php8.0 got "rounded" to php8 causing default.tpl falling back to 8.1 (#2340)
- Fixed an issue with recalculating disk usage (#2341)
- Fixed an issue where php files where still executable in upload folder Wordpress
- Fixed an bug where version numbers includeing revisions (-x) where unable to build properly

## [1.5.3] - Service release

### Features

### Bugfixes

- Fixed an issue where suspended objects where excluded in disk size calculation (#2312 #2313)
- Fixed an issue when a users was unable edit them self when 2FA was enabled (#2314 #2316)
- Fixed an issue in v-add-user-sftp as ftp users where not recognised as valid sftp jail set ups (#2308 #2319)
- Fixed an issue when "Preview" features got disabled it kept the preview features enabled (#2322 #2323)
- Limit access openbase dir hestia-php
- Fixed an issue where an email was send after install nginx command not found (#2328)

### Dependencies

- Update PCRE 8.84 to PCRE2 10.39 for hestia-nginx package
- Update Roundcube to 1.5.2 ([Release notes](https://github.com/roundcube/roundcubemail/releases/tag/1.5.2))
- Update PHPMailer to 6.5.3 ([Release message](https://github.com/PHPMailer/PHPMailer/releases/tag/v6.5.3))

## [1.5.2] - Service release

### Features

- Release notes are now available from the notification panel (#2276)
- Web domain aliases are now displayed in the domain list (#2278 / #2289)
- DNS, Mail, and Database sections will now be hidden in /edit/server if not installed (#2300)
- Turkey has been added as an option for ipset (#2294)

### Bugfixes

- Improvements have been made to overall code quality (#2293, #2298, #2307)
- Added improvements to the automated testing suite (bats) (#2280)
- Clarified text that is shown during upgrade process (#2270)
- Updated web domain templates to allow the use of .user.ini (#2267 / #2269)
- Fixed an issue with the curl symlink on Debian during build process (#2275)
- Fixed an issue where CAA records were deleted when turning off SSL for webmail (#2279)
- Fixed an issue where email validation would fail when using IDN domains (#2273)
- Changed behavior to prevent php-fpm restarts when modphp is installed (#2270)
- Fixed an issue where passwords may not be correctly set on Debian 11 (#2270)
- Fixed an issue with command path v-change-firewall-rule (#2249)
- Fixed an issue in `v-backup-user` where you may encounter an error "invalid parameters for check_result" (#2284)
- Fixed an issue which impacted the performance of Nextcloud/Owncloud ([forum post](https://forum.hestiacp.com/t/tip-create-a-nginx-template-for-nextcloud-to-let-synchronize-files-bigger-than-10mb/5123))
- Fixed an issue where the access port for HestiaCP was not properly set on install (#2288 / #2291)
- Fixed an issue where admins could not log in as a suspended user in the panel (#2286 / #2289)
- Fixed an issue where the "Delete" button in the Edit User interface did not work as expected (#2282 / #2289)
- Fixed an issue where editing an existing firewall rule with ipset would fail (#2292)
- Fixed an error that may occur in /edit/server when no extra php versions were installed (#2289)
- Fixed an issue where accessing the panel via Safari would result in error NSPOSIXErrorDomain:100 (#2274)
- Corrected command syntax in v-delete-dns-records (#2295)
- Fixed an issue where API allowed IP list values would be lost when saving changes (#2296 / #2300)
- Fixed an issue where the debug mode option was not displayed on release builds and would be reset when saving server settings (#2300)
- Fixed an issue where grep would throw an error when adding ipset rules for the first time (#2307)
- Fixed incorrect variable spelling ($v_interace > $v_interface) (#2307)
- Updated mail domain templates
- Updated command line examples for docs.hestiacp.com
- Fixed an issue where Lets encrypt was not able to obtain an valid ssl certificate when force ssl and / or redirect was enabled (#2176 / #2304 / #2304)
- Fixed a issue in v-list-sys-dns-status

### Dependencies

## [1.5.1] - Service release

### Bugfixes

- Add B2 delete file support to BlackBlaze
- Open phpmyadmin in new tab or window #2250 @manuelserol
- Fix issue with ipset not working properly [Forum](https://forum.hestiacp.com/t/error-ipset-object-not-found/5015)
- Improve port detection on multiple servers for SSH #2242 and #2255
- Fixed an issue with # in config files
- Fixed multiple bugs in installer
- Set correct permission /install/deb/ folder
- Adjust /etc/apt/sources.list.d/hestia.list to include architecture to resolve issue with I386 missing in apt.hestiacp.com
- Fallback to hostname without retrying ptr lookup in exim (#2259)
- Enable quota with in dovecot when sieve is enabled @madito
- Unable to edit php8.1 service #2261

### Dependencies

- Update Roundcube to 1.5.1 [Release Notice](https://roundcube.net/news/2021/11/28/update-1.5.1-released)

## [1.5.0] - Major Release (Feature / Quality Update)

### Breaking changes

- **NOTE:** Changes have been made on how phpmyadmin/phppgadmin config are included in apache2 config. To restore to the old behaviour add `IncludeOptional conf.d/*.inc` below `IncludeOptional conf.d/*.conf` in /etc/apache2/apache2.conf and restart your server.
- **NOTE:** Hestia packages for arm64 has been added to atp.hestiacp.com please use the normal install instructions instead! For current ARM installs to enable auto update remove the `#` in /etc/apt/sources.list.d/hestia.list `# deb https://apt.hestiacp.com/ focal main` becomes `deb https://apt.hestiacp.com/ focal main` and then run `apt update && apt upgrade -y`
- **NOTE:** Make sure your server / VPS has a valid PTR record or otherwise you will not be able to send any mail!

### Features

- Add support for Dovecote Sieve #2163 (@gejobj) => [How to enable Managesieve](https://hestiacp.com/docs/server-administration/email.html#how-can-i-enable-managesieve)
- Improve HELO based system and use RDNS lookup instead our old system
- Add support for PHP 8.1 #2233
- Set default php version for new installs to PHP 8.0
- Add support for ARM64 Processors
- Disable access phpmyadmin/phppgadmin over ip address in Apache2 #2072

### Bugfixes

- Disable /reset/ endpoint when POLICY_SYSTEM_PASSWORD_RESET = no #2167
- Add rate limit forgot password #2199
- Prevent SOA count up after v-change-dns-records with no changes are made
- Fix #1296 Log rotate does not rotate logs any more on Ubuntu 20.04 and Debian 11
- Run shellcheck to improve code quality
- Improve ssh port detection for filemanager. Allowing users to create /etc/ssh/sshd.conf.d/custom.conf with custom port
- Fix an bug in v-add-letsencrypt-host due to changes of Lets Encrypt causing issues with rate limiting
- Improve Update process Hestia and allow versions to decide a a rebuild is required
- Add Download SSL certificate function for self generated ssl certificates #2181
- Block access to .user.ini for Nginx + Apache2 #2179
- Add support for download B2 backup to local server to allow for restore #2199
- Update permissions /var/log/roundcube on older installations #2173
- Update translations
- Fix Roundcube permissions
- Add .webp to list of media formats that can be cached by the browser
- Disable /list/log/auth when in Demo mode
- Fix #1139 By force rebuilding webmail config files
- Fix a bug in rebuild mysql database @depca
- Fix #1239 Bug in basic auth not working properly
- Add validation for email address before install server for admin account
- Fix bug in v-change-domain-owner #2210
- Improve input validation Add / Edit User package and improve reading config files to prevent security issues.

### Dependencies

- Update Roundcube to 1.5.0 <https://roundcube.net/news/2021/10/18/roundcube-1.5.0-released>
- Update jQuery UI to the last version [CVE-2021-41182](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-41182)

## [1.4.17] - Service release

### Bugfixes

- Fix bug with nginx and phmyadmin not loading
- Fix #2166 Search function broken
- Update Quick installers to the last version

## [1.4.16] - Service release

### Bugfixes

- Fix bug with .json not loading on Apache2 due to rule in /etc/apache2/conf.d/phpmyadmin.conf

## [1.4.15] - Service release

## Features

- Add templates Chevereto #2153 @ManualRechkle

### Bugfixes

- Fix bug in v-add-sys-ip with netplan active
- Limit access to files/folders that are not required on default /phpmyadmin (\*.json, templates, locale, vendor) #2143
- Update translations
- Fix issue with Exim 4.94 and Autoreply #2151
- Fix multiple UI bugs #2415
- Fix link broken link to Documentation #2142
- Improve detection for MariaDB #2141 thanks @gejobj

## [1.4.14] - Service release

### Bugfixes

- Fixed an issue with edit package
- Fixed an issue with v-update-letsencrypt and v-restart-service
- Fixed an issue with v-add-sys-ip and Ubuntu with no netplan enabled
- Fixed broken UPGRADE_MESSAGE variable not showing up in email
- Include / expand the config backup system during update

## [1.4.13] - Service release

### Features

- Introduce UPGRADE_MESSAGE variable to support custom messages in e-mail upgrade notification.

### Bugfixes

- Improve the hostname check to prevent invalid hostnames or the use of an ip address (RFC1178).
- Prevent CSRF from other domains / websites
- Fix #2096 Hostname SSL got overwritten by mail.hostname.com certificate
- Add small wait for /usr/bin/iptables-restore [Forum](https://forum.hestiacp.com/t/clean-install-arm64-does-not-start-after-reboot-v-start-service-iptables/4395/7) + Fixed v-add-firewall / v-delete-firewall function (#2112) @myrevery
- Fix bug in v-change-sys-api. When using v-change-sys-api remove and then v-change-sys-api enable + custom release branch the resetting of api failed + no "error" output was producted
- Improve error reporting PMA Single sign on function function
- Fixed an issue in v-change-web-domain-name where webserserver where not able to start because old config files where not properly deleted #2104
- Fixed potential XSS vulnerability in /list/keys/ @wtwwer [Disclosure](https://huntr.dev/bounties/0fefa2f6-7024-44c8-87c7-4d01fb93403e/)
- Removed /edit/file as it has been replaced by Filegator and part of the old Vesta Filemanager
- Fixed potential External control / path vulnerability in /add/package @wtwwer [Disclosure](https://huntr.dev/bounties/e0a2c6ff-b4fe-45a2-9d79-1f4dc1b381ab/)
- Add extra checks to prevent type juggling @vikychoi [Disclosure](https://huntr.dev/bounties/c24fb15c-3c84-45c8-af04-a660f8da388f/)
- Improved and updated some missing translation strings @myrevery
- Sync translations with Github

## [1.4.12] - Service release

### Bugfixes

- Allow custom mail domains with own certificates #2061 @myrevery
- Fixed Replace tabulation with \u0009 in v-list-dns-records #2089 @codibit
- Fix #2087 Exim 4.94 Did not send any email to remote servers.
- Fixed #2082 v-delete-web-php creates always new config file
- Add /home/user/.composer in open_basedir #2088 @anvme

## [1.4.11] - Service release

### Features

- Added support for Debian 11 (Bullseye) #1661
- Added support for openssl in hestia-php
- Use hestia-php for installing dependencies to solve issue user configurations (hestia-php 7.4.22 required)
- Replace old firewall system with systemd service / startup script #2064 @myrevery
- Add Quick installers for GravCMS, Docuwiki and Mediawiki (#2002) @PsychotherapistSam

### Bugfixes

- Improve handling upgrade of Roundcube #1917
- Fix an issue with sorting the update scripts when version goes higher then 1.x.10
- Allow the use of multiple CAA records for domain. #2073
- Add missing group (www-data) to migrate_phpmyadmin script #2077 @bet0x
- Fix an issue where <news@domain.com> get forwarded to /var/spool/news
- Synced up translations with HestiaCP (IT, PL, RU, SK and ZN-CN updated)

## [1.4.10] - Service release

### Features

- Added v-delete-firewall-ban ip all #2031
- Include config tests for nginx/apache2 templates

### Bugfixes

- Fixed UI issues after upgrade jQuery + jQuery UI to last version (#2021 and #2032) + [forum](https://forum.hestiacp.com/t/confusion-about-send-welcome-email-checkbox/4259/11)
- Fixed security issues in caching templates of Nginx when used as Reverse Proxy
- Fixed an issue with deleting multiple mail accounts (#2047)
- Fixed an issue with phpmailer + non latin characters (#2050) thanks @Faymir
- Remove caching template for CraftCMS (#2039) @anvme
- Fixed an issue with phpmailer + non latin characters (#2050) thanks @Faymir
- Fix Unable to load dynamic library 'pdo_mysql.so' after php reinstalling (#2069)

## [1.4.9] - Service release

### Bugfixes

- Updated jQuery and jQuery UI to the latest version due to a vulnerability in jQuery. @dependabot
- Fixed bug in /etc/dovecot/conf.d/10-ssl.conf for new installs
- Fixed bug with notifications
- Fixed translation string @myrevery

## [1.4.8] - Service release

### Features

- Add support for automated testing for HestiaCP code with @drone
- Add support for SMTP server for internal email #1988 @Myself5 / #1165

### Bugfixes

- Updated jQuery and jQuery UI to the latest version due to a vulnerability in jQuery. @dependabot
- Resolve issue with double ENFORCE_SUBDOMAIN_OWNERSHIP keys in hestia.conf
- Resolve issue with create new user during install in some cases #2000
- Fixed an issue with Quick Install apps named Test123 (@PsychotherapistSam)
- Fix an issue with dovecot 2.3 ssl config (#1432)
- Load $HESTIA path during upgrade script (#1698)
- Remove TLS 1.1 from Proftpd config (#950)
- Don't remove postfix when Exim is not installed (#1995)
- Fix a bug in no-php Nginx FPM template (##2007)
- Update German translations
- Fixed a few minor error in Mail DMS records (#2005)

## [1.4.7] - Service release

### Bugfixes

- Fixed #1984 phppgadmin not working on apache2 systems
- Fixed #1985 Restart service not working

## [1.4.6] - Service release

### Features

- Add support for custom install hooks #1757
- Add template for CraftCMS #1973 @anvme
- Upgrade Filegator to 7.6.0

### Bugfixes

- Fixed #1961 Renewal Apache2 only SSL certificate fails
- Fixed #1956 to prevent reset of defined webmail client.
- Explicitly disable cron reports #1978
- Fixed an issue where in rare cases certificate failed to install @dpeca and @myvesta
- Fixed an issue where composer failed to install when .composer folder is missing
- Fixed #1980 Lets Encrypt Auto Renewal Reverts Webmail Client back to Roundcube

## [1.4.5] - Service release

### Bugfixes

- Revert #1943 and rework it to fix possible errors occurring on v-rebuild-cron-jobs.
- Fixed #1956 to prevent reset of defined webmail client.
- Explicitly disable cron reports #1978

## [1.4.4] - Service release

### Features

- Add nginx user_agent separation to desktop/mobile (e.g. for fastcgi cache)
- Run phpmyadmin folder under www-data user instead of "user" improving security. (@bet0x)
- Added new template for mod php users to access phpmyadmin

### Bugfixes

- Add template for when webmail is disabled allowing to generate SSL.
- Fixed PHP bug in /list/log/
- Fixed issue with time in /list/services as it was showing as 50 minute1 instead of minutes
- Add missing back buttons + fix behaviour of back buttons on login page.
- Set "default" when WEB_TEMPLATE and PROXY_TEMPLATE is missing in user.conf
- Add BACKEND_TEMPLATE to default package
- Fixed possible error occur for v-rebuild-cron-jobs #1943 (thanks @clarkchentw)
- Restrict access file manager when SSH is enabled for the user (@bet0x)
- Check for DNS domains when running v-change-sys-ip-nat (@clarkchentw)
- Fixed logical error in installer (@clarkchentw)

## [1.4.3] - Service release

### Features

- Include DMARC record in DNS record list #1836
- Enabled phpMyAdmin Single Sign On support #1460
- Add command to add / delete from API_ALLOWED_IP list (#1904)

### Bugfixes

- Improve the calculated disk size of a new backup estimated by excluding the exclude folders, mail accounts and database in backups (#1616) @Myself5
- Improve v-update-firewall / v-stop-firewall to make it self healing (#1892) @myrevery
- Update phpMyAdmin version to 1.5.1 (See <https://www.phpmyadmin.net/news/2021/6/4/phpmyadmin-511-released/>)
- Fixed a bug after rebuilding mail with Exim4 and suspended domains (#1886)
- Fixed "Allowed IP addresses for API" field with strange behaviour #1866
- Fixed an issue where the "Saved confirmation" was not set due to a redirect #1879
- Increased minimal memory requirements for ClamD / ClamAV. #1840
- Restore of backup did not rebuild the "Forced SSL" and "HSTS" config on new account #1862
- Keep changes made by /install/upgrade/manual/install_awstats_geopip.sh on update HestiaCP (via Discord)
- Refactor/improve PHP and HTML code @s0t (#1860)
- Fixed XSS vulnerability in login page and a few other locations @briansemrau / @numanturle
- Delete old session after session_regenerate_id() @briansemrau
- Improve error message when domain all ready exists on different account.
- Fixed an issue where phpmyadmin did not update when Postgresql was available.
- Webmail clients set to rainloop where not able to create a SSL certificate via LE #1913
- Fixed an issue where plugin-hestia-change-pasword did not change the port on v-change-sys-port (Rainloop) #1895
- Fixed an issue where HELO message was not set / error was created on NAT IP

## [1.4.2] - Service release

- **NOTE:** During the 1.4.1 / 1.4.0 release we have introduced a bug for Ubuntu 20.04 and 18.04 users with multiple network ports on the server. This release will solve the problems caused by this bug! If you are unable to download the Hestia packages via apt. Run the following command via CLI or SSH as root

```bash
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Then run the update via

```bash
apt update && apt upgrade
```

### Bugfixes

- Fixed issue wit startup script for iptables / network (#1849) (@myrevery)
- Fixed problem with accidentally replacing nginx.conf during upgrade nginx (#1878 / @myrevery)
- Fixed issue with installing Ubuntu 18.04
- Fixed issue with login into file manger as admin user
- Added proxy_extentions back to support older custom templates
- Added the possibility to skip the forced reboot when interactive is set to no
- Fixed an issue with modx template
- Updated translations (Croatian, Czech and Italian)
- Fixed an issue where users where not able to save / update web domains when POLICY_USER_EDIT_WEB_TEMPLATES is enabled (#1872)
- Fixed an issue where admin users where not able to add new ssh key for users (#1870)
- Fixed an issue where domain.com was not affected as a valid domain (#1874)
- Fixed an issue where "development" icon was not removed on update to release (#1835)

## [1.4.1] - Bug fix

- Fixed bug with 2FA enabled logins

## [1.4.0] - Major Release (Feature / Quality Update)

- **NOTE:** Ubuntu 16.04 (Xenial) is no longer supported as it has reached EOL (end-of-life) status.
- **NOTE:** Apache in "standalone" mode is no longer actively supported and has been removed from installer options. Nginx (Proxy) + Apache2 will remain supported.
- **NOTE:** Custom "quick installer apps" will not work anymore due to changes in how we handle quick installer apps. Minimal changes to the Quick installer apps are required! Please check <https://github.com/hestiacp/hestia-quick-install> for how to migrate!
- **NOTE:** Manual upgrade scripts are available to update Roundcube, Rainloop and PHPmyadmin to the last version they can be found in /usr/local/hestia/install/upgrade/manual/

### Features

- Introduced support for NGINX FastCGI cache.
- Introduced support for SMTP Relay / smarthosts (server-wide or per-domain).
- Introduced the ability to choose which webmail client to use per-domain (Roundcube or Rainloop).
- Added support for Rainloop (Run v-add-sys-rainloop to install it)
- Added B2 Backup Support for Remote Backup Location - thanks **@rez0n**!
- Added template support for osTicket - thanks **@madito**!
- Packages for phpMyAdmin, Roundcube, and Rainloop will be pulled directly from their upstream source instead of APT for new installations.
- Added DNS records view to mail domains which provides DKIM, SPF, and other entries to use with an external provider.
- Added an upgrade script to provide in-place upgrades to php7.4 (or any other version).
- Added Drupal and Nextcloud quick installer support (Removed placeholder Joomla)
- Added a new optional theme "Vestia"
- Added a switch to disable the API and also limit the api by default to 127.0.0.1 only. For current installs added the option "allow-all" on default
- After first reboot of Hestia will try do 1 attempt to request / generate a valid Lets encrypt certificate
- Introduced multiple new security policies via WebUI.
  - Allow users to edit Web / Proxy / DNS / Backend templates
  - Allow users to edit account details
  - Allow suspended users to login with "read-only" access
  - Allow users view / delete user history
  - Enforce sub domain ownership
  - Limit access to admin account when other users have the role "Administrator" assigned to them.
- Disable user to login via WebUI / Limit access to WebUI to certain IP address per user.
- Discourage websites to be created under "admin" account and redirect users to create new users.
- Added support for redirecting to www / non www domains (or custom) #427 / #1638.
- Allow users to see failed login attempts on there account.
- Introduced support for ARM based systems. Currently the packages are not available via ATP!
- Force reboot of system after install

### Bugfixes

- Fixed an issue where user name was duplicated when editing FTP users. (#1411)
- Fixed an issue where the iptables service would appear to be in a stopped state when fail2ban is stopped. (#1374)
- Fixed an issue where the default language value was incorrectly set under Server Settings > Configure.
- Fixed an issue with the dark theme where available updates were incorrectly displayed.
- Fixed an issue where local and FTP backup files were not deleted when running `v-delete-user-backup`. (#1421)
- Fixed an issue where IP addresses could not be deleted. (#1423)
- Fixed an issue where `v-rebuild-user` would incorrectly rebuild domain items in addition to user account configuration.
- Fixed an issue which caused a web domain's custom document root value to be lost when restoring from backup.
- Fixed an issue which caused a `NSPOSIXErrorDomain:100` error when using Safari/iOS (thanks **@stsimb**).
- Fixed an issue where exim ignored the configured mail quota limit.
- Fixed an issue where invalid character validation was performed when editing mail auto replies.
- Fixed an issue which caused Let's Encrypt to fail when using the Moodle template (thanks **@ArturoBlanco**).
- Fixed an issue where the MySQL `wait_timeout` value was not saved due to wrong regexp attribute (thanks **@guicapanema**).
- Fixed an issue where nginx web statistics authorization file was placed in the wrong directory.
- Fixed several small issues that were reported when using PostgreSQL.
- Improved reliability of mail domains and webmail clients.
- Improved reliability of service restarts during upgrades.
- Improved compatibility with Blesta / WHMCS plugins.
- Improved API error handling routines - thanks **@danielalexis**!
- Improved backup performance through the use of multi-threading when creating archives using the `zstd` compression type.
- Improved error handling when creating firewall rules.
- Improved handling of suspended users and domains to allow deletion without unsuspension.
- Improved dependencies over package control to install `lsb-release` and `zstd`.
- Improved SFTP connection handling to be case insensitive (thanks **@lazzurs**).
- Improved domain validation to prevent creating subdomains when the top-level domain belongs to another account (thanks **@KuJoe** and **@sickcodes**).
- Improved IDN domain handling to resolve issues with Let's Encrypt SSL and mail domain services.
- Added private folder to openbasedir permissions for all main templates.
- Disabled changing backup folder via Web UI because it used symbolic link instead of mount causing issues with restore mail / user files.
- Fixed XSS vulnerability in `v-add-sys-ip` and user history log (thanks **@numanturle**).
- Fixed remote code execution vulnerability which could occur when deleting SSH keys (thanks **@numanturle**).
- Fixed vulnerability in v-update-sys-hestia (thanks **@numanturle**)
- Disabled the Update via WebUI due to timeout issues. Please update via `apt update && apt upgrade` in command line instead.
- Improve how Quick install of web apps are handled and allow users added apps to be maintained in list view.
- Fixed an issue where the api was enabled after an update of HestiaCP
- Fixed an issue when the default php version got deleted webmail didn't work any more. #1477
- Limit access when "demo" mode is enabled.
- Fixed an issue where limitations on aliases didn't work properly
- Fixed an issue where "Exit to control pannel" link got changed to "Logout" #1669
- Allow packages to be deleted when in use. Current users are changed to "Default" package.
- Fixed multiple bugs with in v-restore-users
- Redesign statics page
- Allow self signed certificates to be created with aliases.
- Fixed issue where mail accounts where sorting incorrectly by size #1687
- Improve results v-search-command #1703
- Merge Codeiginiter / Drupal templates.
- Prepare template for FastCGI support an improve security by allowing only .well-known for Let's encrypt requests
- Update Cloudflare Ips in nginx.conf
- Fixed an issue where emails where send to nobody when connection failed to database #1765
- Fixed an issue where no notifications where send on failure and save local backup if remote backup failed.
- Fixed an issue where domains containing 2 dots in the top level domain could accidentally got removed #1763
- Fixed an issue where www could be created and after delete webmail doesn't work anymore #1746
- Standardize headers for upgrade scripts
- Improved how we handle custom themes
- Refactored HMTL / PHP code WebUI
- Updated ClamAV configuration
- Fixed issue where file manger key got the wrong permissions
- Update version Laveral @mariojgt

## [1.3.5] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Updated APT repository key for PHP from packages.sury.org (<https://forum.hestiacp.com/t/apt-upgrade-failed-gpg-error-packages-sury-org>)
- Updated phpMyAdmin to v5.1.0.

## [1.3.4] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Fixed xss vulnerability in v-add-sys-ip and user history log (thanks **@numanturle**)
- Fixed remote execution possibility when deleting ssh key (thanks **@numanturle**)

## [1.3.3] - Service Release

### Bugfixes

- Improved if web folder already exists and do not follow symlink on chmod (thanks @0xGsch and @kikoas1995).
- Improved api key authentification to prevent brute force attacks.
- Improved ssh keys folder permission to prevent unauthorized access.

## [1.3.2] - Service Release

### Features

- Added PHP v8.0 support for multiphp environment.

### Bugfixes

- Improved session token handling in login as function, thanks to Vulnerability Laboratory - [Evolution Security GmbH]™.
- Fixed an where fpm pool config was not deleted when changing backend template.
- Improved bats testing with multiphp (5.6-8.0) tests.
- Fixed an issue where full webmail path was loaded as default value.

## [1.3.1] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Fixed an issue where updates for `hestia-php` were incorrectly being marked as out-of-date in the UI due to a change in our servicing and package versioning scheme.
- Fixed an issue that occurred on the Updates page where the table row color of available updates would be difficult to read.
- Fixed an issue where an administrator would get stuck in a loop trying to navigate back after adding a SSH key.
- Fixed an issue where long table entries which exceeded the table length would overlap other UI elements.
- Fixed an issue where the total amount of items on a page would fail to display correctly.
- Improved the accuracy and reliability of tooltips throughout the the Control Panel UI:
  - Removed unnecessary tooltips from buttons and other elements.
  - Fixed incorrect tags which prevented tooltips from being displayed.
  - Introduced tooltips to counter items on the Users, Packages, and Statistics pages to help better distinguish statistics.
- Improved the display of items, quotas, and suspended items in the Control Panel navigation header - thanks **@cmstew**!
- Fixed an issue which caused higher than normal CPU usage during an upgrade due to a duplicate condition in the rebuild process.
- Fixed minor spelling inconsistencies in command line script comments and output text.
- Fixed an issue where old configuration files were not cleaned up when moving domains with `v-change-domain-owner`.
- Fixed an issue where a `no backend template doesn't exist` could potentially would appear after upgrade with older templates (#1322).
- Introduced caching templates for nginx + php-fpm configurations - thanks **@cmstew**!
- Fixed an issue where DNS cluster updates could fail due to the format of a DKIM record in an available zone - thanks **@jrohde**!
- Improved the quality of comment formatting in command line scripts - thanks **@bisubus**!
- Fixed an issue where the logo was not displayed in the File Manager - thanks **@robothemes**!
- Fixed an issue in the Control Panel UI which caused databases and additional FTP accounts to be named incorrectly if manually prefaced with the username.
- Fixed an issue where custom document roots were not saved correctly.
- Improved the visibility of service availability in the Control Panel UI.
- Fixed an issue which let you unsuspend a cronjob on active demo mode.
- Updated DE, EN, ES, KO, NL and TR languages, thanks to @Wibol, Blackjack, @emrahkayihan, areo and @hahagu!
- Fixed an issue which let the auto compiler fail with local src builds.
- Added turkish language to system installers, thanks to @emrahkayihan!
- Fixed incorrect error message when using unknown domain with v-delete-domain.

## [1.3.0] - Major Release (Feature / Quality Update)

### Features

- Users can now choose to point a domain to a different document root location (similar to domain parking).
- The software update process will now perform a system health check before proceeding with installation.
- Administrators now have control over software update notifications through the following settings in `$HESTIA/conf/hestia.conf` and through the Control Panel web interface:
  - `UPGRADE_SEND_EMAIL` = Sends an email notification to primary admin account's email address
  - `UPGRADE_SEND_EMAIL_LOG` = Sends installation log output to the primary admin account's email address
- The upgrade process will now save installation logs to the `/root/hst_backups` directory by default for post-install troubleshooting.
  - **Note:** We may adjust this path in the future and will document such changes as they happen.
- We've introduced the ability to assign Administrator rights to other user accounts, enabling them to perform tasks under the Server Settings tab.
- We've introduced a more robust translation system which will allow us to provide higher quality translations in future releases.
  - **Note:** Some country codes have been updated, as a result your language setting may default back to English after upgrading.
- For new installations, MariaDB 10.5 is now the default version.
  - For existing installations, we've provided a manual post-install upgrade script. Please run `$HESTIA/install/upgrade/manual/upgrade_mariadb.sh` to migrate to MariaDB 10.5).
- The user interface theme has been set to "Dark" by default. This can be changed from **Server Settings > Configure > Basic Options > Appearance**.
  - **Note:** The name of the default theme has not been adjusted, and the change to the "dark" theme only applies to new installations at this time. This behavior may be changed in a future release.

### Bugfixes

- Fixed a security issue where user password reset keys could potentially be gleaned from system process list - thanks **RACK911 LABS**
- Fixed an issue with passwords containing "`'`" - [Forum](https://forum.hestiacp.com/t/two-factor-authentication-issue-with-standard-user/1652/)
- Fixed an issue with database backups when the port was not specified (#1068)
- Fixed an issue where websites without SSL enabled would display the content of the first valid SSL enabled website (#1103)
- Fixed an issue that would occur when using the `--with-debs` flag with the installer due to an incorrect version check routine (#1110)
- Fixed an issue with incorrect permissions which would occur when restoring email accounts (#1114)
- Fixed an issue where the File Manager would apply the wrong permissions on new directories
- Fixed an issue that prevented successful restoration of SSL-enabled mail domains from a backup archive (#1069)
- Fixed an issue where the phpMyAdmin button would not work in the Control Panel Web UI (#1078)
- Fixed an issue where passwords were generated incorrectly (#1184)
- Fixed an issue in `v-add-sys-ip` to ensure IP configuration is set to the correct port - thanks **@madito**
- Fixed an issue that resulted in an extended loop condition when running `v-rebuild-all`
- Improved support for API key usage with the `v-add-remote-dns-host` command (#1265)
- Improved validation of free disk space when executing backup routine (#1115)
- Improved support for SSH key types other than RSA / DSA
- Improved reliability of backup function when removing remote locations (#1083)
- Improved spam filtering by adding additional known-dangerous file extensions in exim's blacklist (#1138) - thanks **@kpapad904**
- Updated Apache2 configuration to use Include with IncludeOptional (#1072)
- Removed the ability to log in as "root" (whic logged to the admin account, deemed no longer necessary)
- Add ca-certificates, software-properties-common to the dependencies (#1073 + [Forum](https://forum.hestiacp.com/t/hestiscp-fails-on-new-debian-9-vps/1623/8)) - thanks **@daniel-eder**
- Create .npm directory by default when creating new user accounts (#1113) - thanks **@hahagu**
- Improved accuracy of several UI translations (NL, DE, UK, RU, ES, IT, ZH-CN) - thanks **@myrevery** and other contributors for your work!
- Added `$restart` flag to `v-add-web-domain-backend` command (#1094) (#797) - thanks **@bright-soft**
- PostgreSQL: forbid the use of upper case (#1084) causing issues with backup / creating database or user
- Changed WordPress name in Quick Web App installer (#1074)
- Cleaned up entries used in the Google / Gmail DNS template - thanks **@madito**
- Enhanced ProFTPd support for TLS
- Refactored LXD compiler script
- Updated phpMyAdmin to version 5.0.4

## [1.2.4] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Fixes an issue on auto renewing let's encrypt certificates.

## [1.2.3] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Fixes an issue where non-ASCII characters were rejected in the password field.

## [1.2.2] - Service Release

### Features

- No new features have been introduced in this release.

### Bugfixes

- Create mailhelo.conf if it doesn't exist to prevent a error message during grep.
- Corrected the display of DNS record types to appear in alphabetical order.
- Fixed an issue where the DNS record type field would reset if an error occurred while adding a new DNS record. (#992)
- Fixed an issue where the DNS domain hint would not appear correctly when editing a DNS record. (#993)
- Fixed an issue where a DNS record would become malformed if changed from A to CNAME. (#988)
- Fixed an issue with the back button on the DNS records page. (#989)
- Fixed an issue where phpMyAdmin/phpPgAdmin would not load correctly due to an incorrect vhost configuration. (#970)
- Fixed an issue where malformed JSON output was returned when custom theme files are present. (#967)
- Fixed an error that would occur when running `v-change-user-php-cli` for the first time if .bash_aliases did not exist. (#960)
- Corrected an issue where tooltips were not displayed when hovering over the top level menu items.
- Improved handling of APT repository keys during installation.
- Reworked the Let's Encrypt renew functionality to skip removed aliases.
- Improved reliability of list handling when using IP lists.
- Enforce minimum password requirements with visual indication of password strength.
- Fixed an issue where user display name value was incorrectly set when changing packages.
- Improved installer version detection.
- Improved detection of MariaDB and MySQL services.

## [1.2.1] - Service Release

### Features

- Consolidated First and Last Name fields to a singular name field to simply input.
  - v-change-user-name will now accept both "First Last" (single argument) and First Last (two arguments) for backward compatibility.
- Removed ntpdate from new installations and enable systemd timesync daemon instead (thanks **@braewoods**)

### Bugfixes

- Fixed an issue where Composer would fail to install due to missing default directory.
- Corrected an issue where two-factor authentication validation was causing high CPU load during the login process. The login screen has been re-designed as a multi-step process (Username > Password > OTP PIN).
- Corrected an issue where text entry fields on the login screen were not automatically focused by default.
- Fixed an issue where RDNS value was incorrectly set if dig failed to resolve the server name.
- Fixed an issue where icons were pushed down in the header when using Bulgarian as the display language. (#932)
- Fixed an issue where new backups were not created when running v-schedule-user-backup-download. (#918)
- Fixed an issue where default configuration files and templates were not backed up correctly.
- Improved quality of default web domain templates for Drupal. (#916)
- Added missing strings to translation files (translations to follow).
- Corrected an issue where toolbars were out of place on the Mail and Firewall pages when using Bulgarian or Greek languages due to string length.
- Improved Spanish translations (thanks **@Wibol**)
- Improved German translations (thanks **@ronald-at**)
- Improved Russian translations (thanks **@Pleskan**)

## [1.2.0] - Major Release (Feature / Quality Update)

### Features

- **NOTE:** Debian 8 is no longer supported as it has reached EOL (end-of-life) status.
- Added support for Ubuntu Server 20.04 LTS.
- Added File Manager functionality (with File Gator backend) with the ability to add or remove at any time (`v-add-sys-filemanager` and `v-delete-sys-filemanager`)
- Extended built-in firewall to support allowing or blocking traffic using IP lists.
- Improved Apache2 performance by switching to mpm_event instead mod_prefork by default for new installations.
- Added support for configuring individual TTL per DNS record. Thanks to **@jaapmarcus**!
- Updated translations for Polish (thanks to @RejectPL!), Dutch, French, German, and Italian (WIP).
- Added the ability to set the default PHP command line version per-user.
- Added geolocation support to awstats to improve traffic reports.
- Enabled Roundcube plugins newmail_notifier and zipdownload by default.
- Added HELO support for multiple domains and IPs.
- Added the ability to manage SSH keys from CLI and web interface.
- Added a manual migration script for apache2 mpm_event for existing installations/upgrades (`$HESTIA/install/upgrade/manual/migrate_mpm_event.sh`).
- Added BATS system for testing the functionality of Bash scripts (WIP).
- Added **v-change-sys-db-alias** to change phpMyAdmin and phpPgAdmin access points (`v-change-sys-db-alias pma/pga myCustomURL`).

### Bugfixes

- Prevent ability to change the password of a non-Hestia user account. Thanks to **Alexandre Zanni**!
- Adjust Let's Encrypt validation check for IDN domains, thanks to **@zanami**!
- Set backup download location on FTP/SFTP restore, thanks to **@Daniyal-Javani**!
- Stop trying to renew Let's Encrypt certificates after multiple consecutive failed attempts. Thanks to **@dpeca**!
- Fixed an issue with auto-logout when used behind Cloudflare proxy and reworked 2FA authentication part. Thanks to **@rmj-s**!
- Fixed an issue where changing an email account password would fail if similar account names were present.
- Fixed an issue where e-mail quota was not preserved when (un)suspending or rebuilding a mail account.
- Fixed an issue where SSH configuration was not saved currently when edited from the Web interface.
- Fixed an issue where DNS IP did not use NAT/Public IP when available after changing web domain IP.
- Fixed an issue that would occur when a user would attempt to recover their account when two-factor authentication is enabled.
- Fixed permission issues that were presented when restoring a user backup.
- Improved page load performance of Control Panel web interface.
- Use Sury.org repository for Apache2 packages.
- Improved compatibility with Roundcube and PHP 7.4.
- Restrict the ability to edit crontab service via Control Panel web interface.
- Check whether Nginx, Apache2 and MariaDB are selected for installation prior to adding third party repositories.
- Restrict public access to Apache2 server-status page.
- Remove duplicated set-cookie line in default fpm config.
- Ignore empty lines when listing firewall rules.
- Improved top-level navigation in the Control Panel web interface (Server tab has been moved next to the Notification icon).
- Corrected various minor user interface and theme issues.
- Cleanup temporary files when uploading custom SSL certificate from Web interface.
- Cleanup temporary files when adding/renewing Let's Encrypt SSL certificate.
- Cleanup temporary files after running v-list-sys-services.
- Removed some legacy code and unused assets.
- Don't calculate /home folder size in v-list-sys-info.
- Adjust v-list-sys-services to honor the changed fail2ban service name.
- Rework busy port validation in v-change-sys-port.
- Implement a validation function to verify the correct version in hestia.conf prior to installation.
- Introduced a delay when an incorrect username, password, or 2FA code has been entered repeatedly.
- Improved "Forgot password" function prevent brute force attacks.
- Fixed an issue where the backup update counter was not updated properly when v-delete-user-backup was executed.
- Fixed an issue with public\_(s)html file ownership.
- Fixed an issue with phpPgAdmin access.
- Fixed an issue where the wrong port was set for <www.conf> on certain configurations.
- Fixed an issue where Composer would fail to install.
- Fixed an issue where the selected theme was not immediately applied.
- Fixed an issue where HTTP-to-HTTPS redirection and HTTP Strict Transport Security (HSTS) events were not shown in the user history log.
- Fixed an issue where the web domain access log page was incorrectly formatted.
- Fixed an issue where awstats would show a HostAliases error if a web domain did not have any aliases.
- Fixed an issue where awstats configuration was not updated if web domain aliases were added or removed.
- Fixed an issue where user interface elements would overlap or display in the wrong place when using non-English locales.
- Fixed an issue where phpMyAdmin and phpPgAdmin were inaccessible from the Web UI if custom URLs had been set.
- Fixed an issue where mail SSL certificates were not restored properly from a backup archive.
- Fixed an issue where mail domain configuration files were not removed when the domain was deleted.
- Improved the functionality of `v-change-domain-owner` to correctly move mail domains and provide status output and logging/notifications.
- Improved the functionality of `v-update-sys-hestia-git` to allow user to specify GitHub repository and whether to build only core package or core and dependencies.
- Corrected the behavior of phpMyAdmin and phpPgAdmin so that alias dialogs accept custom word only and not full URL, aligns with webmail alias behavior.
- Corrected the behavior of the installer so that APT repositories are not added if installation is aborted due to version mismatch.
- Fixed an issue where upgrade procedures were not executed correctly when skipping between versions (e.g. 1.0.6 > 1.2.0).

### Known issues and notes

- **NOTE:** Custom phpMyAdmin and phpPgAdmin URL's will be reset once during this upgrade to correct a legacy code issue.
- Let's Encrypt renewal fails when removing alias from web domain (#856)
- Some translation strings need to be updated for accuracy (#746)
- v-restore-user only works with backup archives stored in /backup mount point (#641)

## [1.1.1] - 2020-03-24 - Hotfix

### Features

- No new features introduced with v1.1.1, this is strictly a security/bug fix release.

### Bugfixes

- Fixed phpMyAdmin blowfish and tmp directory issues.
- Added additional verification of host domain in password reset. Thanks to @FalzoMAD and @mmetince!
- Fixed issue with rc.local not executing properly.
- Rework of Let's Encrypt routine to use progressive delay between validation retries.
- Fixed syntax issue in v-list-sys-db-status which prevented main functions from loading.
- Removed /home size reporting when running v-list-sys-info due to performance issues.
- Updated installer to use Ubuntu key server for Hestia APT repository.
- Fixed duplicate demo mode check in v-change-user-password.

## [1.1.0] - 2020-03-11 - Major Release (Feature / Quality Update)

### Features

- Added support for custom user interface themes.
- Introduced official Dark and Flat themes.
- Added read-only/demo mode - DEMO_MODE must be set to yes in hestia.conf to enable.
- Added php-imagick module to installer and upgrade scripts.
- Added recidive filter function to fail2ban.
- Improved and refactored Multi-PHP functionality.
- Multi-PHP will be enabled by default on new installations.
- Allow admin user to add/remove PHP versions from Web UI (Server -> Configure -> Web Server).
- Extended v-extract-fs-archive to allow archive testing and extracting only specific paths (for tar)
- Allow renaming of existing packages from console (v-rename-package).
- Added PHP 7.4 to Multi-PHP.
- Addded official support for Debian 10 (Buster).

### Bugfixes

- Added a detection of web root for add .well-known ACME challenge.
- Reworked Let's Encrypt ACME staging to use Hestia code standards.
- Fixed issues with incorrect font rendering on Windows and Linux.
- Fixed issues with Let's Encrypt - use Nginx for Let's Encrypt ACME request if present.
- Reworked v-add-sys-ip, removed deprecated CentOS/Red Hat code and reworked conditions.
- Enabled HSTS and force SSL on v-add-letsencrypt-host.
- Removed hardcoded mail in HELO data (cosmetic fix).
- Fixed SFTP server validation check - thanks @dbannik.
- Implemented security warning message when creating web domains with the default admin account.
- Fixed wrong quotes used for default keys folder location in v-generate-api-key backend script.
- Fixed permissions to allow access for FTP users created in web domains under admin account.
- Check if user home directory exists before setting permissions on SFTP fail2ban jail.
- Fixed several reported security issues, thanks to Andrea Cardaci (<https://cardaci.xyz/>)
- Security fix: Command line arguments arguments were glob expanded when written to log file.
- Ensure that SFTP accounts remain configured in sshd when removing web domains/
- Improved security by ensuring that file operations in user home folder will be executed as the real user.
- Added a confirmation dialog when deleting user logs.
- Fixed an issue where the SFTP fail2ban jail was not working correctly for user accounts which were restored from backup archives.
- Enhanced input validation in backend command line scripts.
- Improved page load performance by optimizing how the notifications list is loaded (in some cases, improvement measured from 1sec to under 100ms).
- Improved page load performance when loading IP ban rules in the Control Panel.
- Updated panel framework to use jQuery to 3.4.1.
- Fixed an issue with SFTP fail2ban jail due to missing user.
- Fixed an issue where remote backup hostname would reject an IP address without reverse DNS (PTR record). (#569)
- Create default writable folders in user home directory (#580).
- Added gnupg/gnupg2 check to prevent issues with pubkey installation.
- Fixed DNS nameserver validation when adding new packages.
- Implemented additional debug information for Let's Encrypt validation - thanks @shakaran.
- Disabled alerts for successful cronjob backups.
- Fixed an issue with suspending resources when logged in as a normal (non admin) user.
- Fixed an issue with unsuspending a user, PHP-FPM website pool configuration was being deleted.
- Fixed potential upgrade issue when using v-update-sys-hestia-git.
- Fixed corruption of global user stats when rebuilding a mail domain.
- Fixed formatting of backup exclusions textbox.
- Fixed MultiPHP upgrade script to update all web templates.
- Fixed report issue link in installer scripts.
- Fixed database user authentification on backup restore.
- Added robots.txt for Roundcube webmail to prevent search bot crawling.
- Re-Enable force ssl function on let's encrypt certification renew.
- Added official PostgreSQL repository so system stays up-to-date with latest available upstream packages.
- Hardening MySQL configuration, prevent local infile.
- Fixed lograte bug and cleans up the messed up nginx/apache2 log permissions.
- Fixed IfModule mpm_itk.c for apache2 templates.
- Added mpm_itk for Debian 10 (non Multi-PHP installations only.)
- Hardening nginx configuration, dropped support for TLSv1.1.
- Fixed excluding folders named "logs" from restore backup, thanks to @davidgolsen.
- Fixed typo in delete psql database part, thanks to @joshbmarshall.
- Split long txt records to 255 chunks to prevent bind issues, thanks to @setiseta.
- Fixed missing restart routine for vsftp on v-add-letsencrypt-host.
- Show amount of disk space consumed by /home when running v-list-sys-info.
- Remove broken /webmail alias from previous versions.
- Webmail IP address is now inherited from web domain when using multiple IPs.
- Exim now uses the web domain IP if it exists.
- Fixed incorrect MX record for DNS domains using the Office 365 template.

## [1.0.6] - 2019-09-24 - Hotfix

### Bugfixes

- Add support for HTTP/2 Let's Encrypt Server.

## [1.0.5] - 2019-08-06 - Hotfix

### Bugfixes

- Fixed several security issues, thanks to Andrea Cardaci (<https://cardaci.xyz/>)
- Rework Let's Encrypt ACME staging to use hestia conform standard.
- Fixed if condition, use nginx for Let's Encrypt ACME request if present.

## [1.0.4] - 2019-07-09 - Hotfix

### Bugfixes

- Delayed start of services to prevent restart limit.

## [1.0.3] - 2019-07-09 - Hotfix

### Bugfixes

- Fixed Let's Encrypt Mail SSL permission issue.

## [1.0.1] - 2019-06-25

### Features

- Improved support for Let's Encrypt certificate generation.
- v-add-letsencrypt-host: Added Let's Encrypt support for Control Panel's own SSL.
- Enabled use of per-domain SSL certificates for inbound and outbound mail services.
- Consolidated template structure, removing over 50% duplicate code.
- Re-organised file system structure for domain configuration files.
- Added the ability to change release branches through the user interface and the command line.
- v-sys-update-hestia-git: Added the ability to update using Git from the command line.
- Implemented support for SFTP chroot jails.
- A newly redesigned user interface which features:
  - A softer color palette which better matches the Hestia Control Panel logo colors.
  - A consolidated overview of domains and other information.
  - Improved navigation paths to make things easier to find.
  - Improved compatibility when viewing the Control Panel interface from a mobile device.
- Improved handling of mail domain DNS zone values.
- Enabled OCSP stapling on SSL-enabled web domains.
- v-change-web-domain-hsts: Enabled support for HTTP Strict Transport Security (HSTS) on SSL.
- Improved logging and console output during new installations and upgrades.

### Bugfixes

- Fixed issues with HTTP-to-HTTPS redirecton.
- Fixed an issue where another website would load if browsing to a non-SSL enabled domaing using HTTPS.

## [1.0.0-190618] - 2019-06-25

### Features

-

### Bugfixes

-

## [0.9.8-28] - 2019-05-16

### Features

- Implemented force SSL function for web domains.

### Bugfixes

-

[1.0.4]: https://github.com/hestiacp/hestiacp/releases/tag/1.0.4
[1.0.3]: https://github.com/hestiacp/hestiacp/releases/tag/1.0.3
[1.0.1]: https://github.com/hestiacp/hestiacp/releases/tag/1.0.1
[1.0.0-190618]: https://github.com/hestiacp/hestiacp/releases/tag/1.0.0-190618
[0.9.8-28]: https://github.com/hestiacp/hestiacp/releases/tag/0.9.8-28
