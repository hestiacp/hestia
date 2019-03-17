#!/bin/bash

HESTIA_BACKUP="/root/hst_upgrade/$(date +%d%m%Y%H%M)"
HESTIA="/usr/local/hestia"

# Create backup directory
mkdir -p $HESTIA_BACKUP

# Set version(s)
pma_v='4.8.5'

# Upgrade phpMyAdmin
if [ "$DB_SYSTEM" = 'mysql' ]; then
    # Display upgrade information
    echo "Upgrade phpMyAdmin to v$pma_v..."

    # Download latest phpMyAdmin release
    wget --quiet https://files.phpmyadmin.net/phpMyAdmin/$pma_v/phpMyAdmin-$pma_v-all-languages.tar.gz

    # Unpack files
    tar xzf phpMyAdmin-$pma_v-all-languages.tar.gz

    # Delete file to prevent error
    rm -fr /usr/share/phpmyadmin/doc/html

    # Overwrite old files
    cp -rf phpMyAdmin-$pma_v-all-languages/* /usr/share/phpmyadmin

    # Set config and log directory
    sed -i "s|define('CONFIG_DIR', '');|define('CONFIG_DIR', '/etc/phpmyadmin/');|" /usr/share/phpmyadmin/libraries/vendor_config.php
    sed -i "s|define('TEMP_DIR', './tmp/');|define('TEMP_DIR', '/var/lib/phpmyadmin/tmp/');|" /usr/share/phpmyadmin/libraries/vendor_config.php

    # Create temporary folder and change permissions
    if [ ! -d /usr/share/phpmyadmin/tmp ]; then
        mkdir /usr/share/phpmyadmin/tmp
        chmod 777 /usr/share/phpmyadmin/tmp
    fi

    # Clean up
    rm -fr phpMyAdmin-$pma_v-all-languages
    rm -f phpMyAdmin-$pma_v-all-languages.tar.gz
fi

# Add amd64 to repositories to prevent notifications - https://goo.gl/hmsSV7
if ! grep -q 'arch=amd64' /etc/apt/sources.list.d/nginx.list; then
    sed -i s/"deb "/"deb [arch=amd64] "/g /etc/apt/sources.list.d/nginx.list
fi
if ! grep -q 'arch=amd64' /etc/apt/sources.list.d/mariadb.list; then
    sed -i s/"deb "/"deb [arch=amd64] "/g /etc/apt/sources.list.d/mariadb.list
fi

# Fix named rule for AppArmor - https://goo.gl/SPqHdq
if [ "$DNS_SYSTEM" = 'bind9' ] && [ ! -f /etc/apparmor.d/local/usr.sbin.named ]; then
        echo "/home/** rwm," >> /etc/apparmor.d/local/usr.sbin.named 2> /dev/null
fi

# Remove obsolete ports.conf if exists.
if [ -f $HESTIA/data/firewall/ports.conf ]; then
    rm -f $HESTIA/data/firewall/ports.conf
fi

# Reset backend port
if [ ! -z "$BACKEND_PORT" ]; then
    $HESTIA/bin/v-change-sys-port $BACKEND_PORT
fi

# Set Purge to false in roundcube config - https://goo.gl/3Nja3u
if [ -f /etc/roundcube/config.inc.php ]; then
    sed -i "s/deletion'] = 'Purge'/deletion'] = false/g" /etc/roundcube/config.inc.php
fi
if [ -f /etc/roundcube/main.inc.php ]; then
    sed -i "s/deletion'] = 'Purge'/deletion'] = false/g" /etc/roundcube/main.inc.php
fi

# Enable spell-check exception dictionary for Roundcube users
if [ -f /etc/roundcube/config.inc.php ]; then
    sed -i "s/spellcheck_dictionary'] = false/spellcheck_dictionary'] = true/g" /etc/roundcube/config.inc.php
fi
if [ -f /etc/roundcube/main.inc.php ]; then
    sed -i "s/spellcheck_dictionary'] = false/spellcheck_dictionary'] = true/g" /etc/roundcube/main.inc.php
fi

# Update Office 365 DNS templates
if [ -f $HESTIA/data/templates/dns/o365.tpl ]; then
    rm -f $HESTIA/data/templates/dns/o365.tpl 
    cp -f $HESTIA/install/hestia-data/templates/dns/office365.tpl $HESTIA/data/templates/dns/
fi

# Update default page templates
echo '************************************************************************'
echo "* Upgrading default page templates...                                  *"
echo "* Existing templates have been backed up to the following location:    *"
echo "* $HESTIA_BACKUP/templates/                                            *"
echo '************************************************************************'

if [ -d $HESTIA/data/templates/ ]; then
    # Back up old template set
    mkdir -p $HESTIA_BACKUP/templates/
    cp -rf $HESTIA/data/templates/* $HESTIA_BACKUP/

    # Back up and remove default index.html if it exists
    if [ -f /var/www/html/index.html ]; then
        cp -rf /var/www/html/index.html $HESTIA_BACKUP/templates/
        rm -rf /var/www/html/index.html
    fi

    # Remove old default page templates
    rm -rf $HESTIA/data/templates/web/skel/*
    rm -rf $HESTIA/data/templates/web/suspend/*
    mkdir -p $HESTIA/data/templates/web/unassigned/

    # Copy new default templates to Hestia installation
    cp -rf $HESTIA/install/hestia-data/templates/web/skel/* $HESTIA/data/templates/web/skel/
    cp -rf $HESTIA/install/hestia-data/templates/web/suspend/* $HESTIA/data/templates/web/suspend/
    cp -rf $HESTIA/install/hestia-data/templates/web/unassigned/* $HESTIA/data/templates/web/unassigned/
    cp -rf $HESTIA/install/hestia-data/templates/web/unassigned/* /var/www/html/

    # Correct permissions on CSS, JavaScript, and Font dependencies for unassigned hosts
    chmod 644 /var/www/html/*
    chmod 751 /var/www/html/css
    chmod 751 /var/www/html/js
    chmod 751 /var/www/html/webfonts
    
    # Correct permissions on CSS, JavaScript, and Font dependencies for default templates
    chmod 751 $HESTIA/data/templates/web/skel/document_errors/css
    chmod 751 $HESTIA/data/templates/web/skel/document_errors/js
    chmod 751 $HESTIA/data/templates/web/skel/document_errors/webfonts
    chmod 751 $HESTIA/data/templates/web/skel/public_*html/css
    chmod 751 $HESTIA/data/templates/web/skel/public_*html/js
    chmod 751 $HESTIA/data/templates/web/skel/public_*html/webfonts
    chmod 751 $HESTIA/data/templates/web/suspend/css
    chmod 751 $HESTIA/data/templates/web/suspend/js
    chmod 751 $HESTIA/data/templates/web/suspend/webfonts
    chmod 751 $HESTIA/data/templates/web/unassigned/css
    chmod 751 $HESTIA/data/templates/web/unassigned/js
    chmod 751 $HESTIA/data/templates/web/unassigned/webfonts
fi

# Move clamav to proper location - https://goo.gl/zNuM11
if [ ! -d $HESTIA/web/edit/server/clamav-daemon ]; then
    mv $HESTIA/web/edit/server/clamd $HESTIA/web/edit/server/clamav-daemon
fi

# Fix dovecot configuration
if [ -f /etc/dovecot/conf.d/15-mailboxes.conf ]; then
    # Remove mailboxes configuration if it exists
    rm -f /etc/dovecot/conf.d/15-mailboxes.conf
fi
if [ -f /etc/dovecot/dovecot.conf ]; then
    # Update dovecot configuration and restart dovecot service
    cp -f $HESTIA/install/hestia-data/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
    systemctl restart dovecot
fi

# Rebuild mailboxes
for user in `ls $HESTIA/data/users/`; do
    $HESTIA/bin/v-rebuild-mail-domains $user
done

# Remove old OS-specific installation files if they exist to free up space
if [ -d $HESTIA/install/ubuntu ]; then
    rm -rf $HESTIA/install/ubuntu
fi
if [ -d $HESTIA/install/debian ]; then
    rm -rf $HESTIA/install/debian
fi