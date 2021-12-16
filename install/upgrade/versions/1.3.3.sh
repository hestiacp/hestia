#!/bin/bash

# Hestia Control Panel upgrade script for target version 1.3.3

#######################################################################################
#######                      Place additional commands below.                   #######
#######################################################################################


# Check if keys folder exists and adjust permissions
if [ -d "$HESTIA/data/keys" ]; then
    echo '[ * ] Update permissions'
    chmod 750 "$HESTIA/data/keys"
    chown admin:root "$HESTIA/data/keys"
fi

if [[ ! -e /etc/hestiacp/hestia.conf ]]; then
    echo '[ * ] Create global Hestia config'

    mkdir -p /etc/hestiacp
    echo -e "# Do not edit this file, will get overwritten on next upgrade, use /etc/hestiacp/local.conf instead\n\nexport HESTIA='/usr/local/hestia'\n\n[[ -f /etc/hestiacp/local.conf ]] && source /etc/hestiacp/local.conf" > /etc/hestiacp/hestia.conf
fi
