#!/bin/bash

# Hestia Control Panel upgrade script for target version 1.4.11

#######################################################################################
#######                      Place additional commands below.                   #######
#######################################################################################

# Fix the potential issue of loading firewall rules
if [ "$FIREWALL_SYSTEM" = "iptables" ]; then
    echo "[ * ] Fix the potential issue of loading firewall rules..."
    # Just in case, delete the legacy version loading script again to prevent any residue
    rm -f /usr/lib/networkd-dispatcher/routable.d/50-ifup-hooks /etc/network/if-pre-up.d/iptables
    # The firewall rules are loading by Systemd, the old loading script is no longer needed
    rm -f /usr/lib/networkd-dispatcher/routable.d/10-hestia-iptables /etc/network/if-pre-up.d/hestia-iptables
    $BIN/v-update-firewall
fi
