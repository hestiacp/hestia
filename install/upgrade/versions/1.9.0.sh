#!/bin/bash

# Hestia Control Panel upgrade script for target version 1.9.0

#######################################################################################
#######                      Place additional commands below.                   #######
#######################################################################################
####### upgrade_config_set_value only accepts true or false.                    #######
#######                                                                         #######
####### Pass through information to the end user in case of a issue or problem  #######
#######                                                                         #######
####### Use add_upgrade_message "My message here" to include a message          #######
####### in the upgrade notification email. Example:                             #######
#######                                                                         #######
####### add_upgrade_message "My message here"                                   #######
#######                                                                         #######
####### You can use \n within the string to create new lines.                   #######
#######################################################################################

upgrade_config_set_value 'UPGRADE_UPDATE_WEB_TEMPLATES' 'false'
upgrade_config_set_value 'UPGRADE_UPDATE_DNS_TEMPLATES' 'false'
upgrade_config_set_value 'UPGRADE_UPDATE_MAIL_TEMPLATES' 'false'
upgrade_config_set_value 'UPGRADE_REBUILD_USERS' 'yes'
upgrade_config_set_value 'UPGRADE_UPDATE_FILEMANAGER_CONFIG' 'false'

# update config sftp jail
$BIN/v-delete-sys-sftp-jail
$BIN/v-add-sys-sftp-jail

# Check if hestiaweb exists
if [ -z "$(grep ^hestiaweb: /etc/passwd)" ]; then
	# Generate a random password
	random_password=$(generate_password '32')
	# Create the new hestiaweb user
	/usr/sbin/useradd "hestiaweb" -c "$email" --no-create-home
	# do not allow login into hestiaweb user
	echo hestiaweb:$random_password | sudo chpasswd -e
	cp $HESTIA_COMMON_DIR/sudo/hestiaweb /etc/sudoers.d/
	# Keep enabled for now
	# Remove sudo permissions admin user
	# rm /etc/sudoers.d/admin/
fi

# Check if cronjobs have been migrated
if [ ! -f "/var/spool/cron/crontabs/hestiaweb" ]; then
	echo "MAILTO=\"\"" > /var/spool/cron/crontabs/hestiaweb
	echo "CONTENT_TYPE=\"text/plain; charset=utf-8\"" >> /var/spool/cron/crontabs/hestiaweb
	while read line; do
		parse_object_kv_list "$line"
		if [ -n "$(echo "$CMD" | grep ^sudo)" ]; then
			echo "$MIN $HOUR $DAY $MONTH $WDAY $CMD" \
				| sed -e "s/%quote%/'/g" -e "s/%dots%/:/g" \
					>> /var/spool/cron/crontabs/hestiaweb
			$BIN/v-delete-cron-job admin "$JOB"
		fi
	done < $HESTIA/data/users/admin/cron.conf
	# Update permissions
	chmod 600 /var/spool/cron/crontabs/hestiaweb
	chown hestiaweb:hestiaweb /var/spool/cron/crontabs/hestiaweb

fi

chown hestiaweb:hestiaweb /usr/local/hestia/data/sessions

packages=$(ls --sort=time $HESTIA/data/packages | grep .pkg)
# Update Hestia Packages
for package in $packages; do
	if [ -z "$(grep -e 'BACKUPS_INCREMENTAL' $HESTIA/data/packages/$package)" ]; then
		echo "BACKUPS_INCREMENTAL='no'" >> $HESTIA/data/packages/$package
	fi

	# Add additional key-value pairs if they don't exist
	for key in DISK_QUOTA CPU_QUOTA CPU_QUOTA_PERIOD MEMORY_LIMIT SWAP_LIMIT; do
		if [ -z "$(grep -e "$key" $HESTIA/data/packages/$package)" ]; then
			echo "$key='unlimited'" >> $HESTIA/data/packages/$package
		fi
	done
done

# Add xferlog to vsftpd logrotate
if [ -s /etc/logrotate.d/vsftpd ] && ! grep -Fq "/var/log/xferlog" /etc/logrotate.d/vsftpd; then
	sed -i 's|/var/log/vsftpd.log|/var/log/vsftpd.log /var/log/xferlog|g' /etc/logrotate.d/vsftpd
fi

# Use only TLS 1.2 cipher suites for vsftpd
if [ -s /etc/vsftpd.conf ]; then
	sed -i "s/ssl_ciphers.*/ssl_ciphers=ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305/g" /etc/vsftpd.conf
fi

# Increase max connections and limit number of connections per host for Exim
if [ -s /etc/exim4/exim4.conf.template ] && ! grep -Fq "smtp_accept_max" /etc/exim4/exim4.conf.template; then
	sed -i '/disable_ipv6 = true/a\smtp_accept_max = 100\nsmtp_accept_max_per_host = 20' /etc/exim4/exim4.conf.template
fi

# Update phymyadmin.inc for nginx
if [ -s /etc/nginx/conf.d/phpmyadmin.inc ]; then
	cp -f $HESTIA_INSTALL_DIR/nginx/phpmyadmin.inc /etc/nginx/conf.d/phpmyadmin.inc
fi

$BIN/v-add-user-notification 'admin' 'Hestia security has been upgraded' ' A new user "hestiaweb" has been created and is used for login. Make sure other Hestia packages are updated as well otherwise the system may not work as expected.'
add_upgrade_message 'Security has been upgraded, A new user "hestiaweb" has been created and is used for login. Make sure other Hestia packages are updated as well otherwise the system may not work as expected.'
# Ensures proper permissions for Hestia service interactions.
/usr/sbin/adduser hestiamail hestia-users

locale_file="/etc/default/locale"
if ! grep -qiE "utf-?8" "$locale_file"; then
	echo "Phrase 'utf8' or 'utf-8' not found in $locale_file. Switching to C.UTF-8"
	sudo locale-gen C.UTF-8
	echo 'LANG="C.UTF-8"' | sudo tee "$locale_file"
	sudo update-locale
	export LANG=C.UTF-8
fi
