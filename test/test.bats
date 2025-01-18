#!/usr/bin/env bats

if [ "${PATH#*/usr/local/hestia/bin*}" = "$PATH" ]; then
    . /etc/profile.d/hestia.sh
fi

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'


function random() {
    head /dev/urandom | tr -dc 0-9 | head -c$1
}

function setup() {
    # echo "# Setup_file" > &3
    if [ $BATS_TEST_NUMBER = 1 ]; then
        echo 'user=test-5285' > /tmp/hestia-test-env.sh
        echo 'user2=test-5286' >> /tmp/hestia-test-env.sh
        echo 'userbk=testbk-5285' >> /tmp/hestia-test-env.sh
        echo 'userpass1=test-5285' >> /tmp/hestia-test-env.sh
        echo 'userpass2=t3st-p4ssw0rd' >> /tmp/hestia-test-env.sh
        echo 'HESTIA=/usr/local/hestia' >> /tmp/hestia-test-env.sh
        echo 'domain=test-5285.hestiacp.com' >> /tmp/hestia-test-env.sh
        echo 'domainuk=test-5285.hestiacp.com.uk' >> /tmp/hestia-test-env.sh
        echo 'rootdomain=testhestiacp.com' >> /tmp/hestia-test-env.sh
        echo 'subdomain=cdn.testhestiacp.com' >> /tmp/hestia-test-env.sh
        echo 'database=test-5285_database' >> /tmp/hestia-test-env.sh
        echo 'dbuser=test-5285_dbuser' >> /tmp/hestia-test-env.sh
        echo 'pguser=test5290' >> /tmp/hestia-test-env.sh
        echo 'pgdatabase=test5290_database' >> /tmp/hestia-test-env.sh
        echo 'pgdbuser=test5290_dbuser' >> /tmp/hestia-test-env.sh
    fi

    source /tmp/hestia-test-env.sh
    source $HESTIA/func/main.sh
    source $HESTIA/conf/hestia.conf
    source $HESTIA/func/ip.sh
}

function validate_web_domain() {
    local user=$1
    local domain=$2
    local webproof=$3
    local webpath=${4}

    refute [ -z "$user" ]
    refute [ -z "$domain" ]
    refute [ -z "$webproof" ]

    source $HESTIA/func/ip.sh

    run v-list-web-domain $user $domain
    assert_success

    USER_DATA=$HESTIA/data/users/$user
    local domain_ip=$(get_object_value 'web' 'DOMAIN' "$domain" '$IP')
    SSL=$(get_object_value 'web' 'DOMAIN' "$domain" '$SSL')
    domain_ip=$(get_real_ip "$domain_ip")

    if [ ! -z $webpath ]; then
        domain_docroot=$(get_object_value 'web' 'DOMAIN' "$domain" '$CUSTOM_DOCROOT')
        if [ -n "$domain_docroot" ] && [ -d "$domain_docroot" ]; then
            assert_file_exist "${domain_docroot}/${webpath}"
        else
            assert_file_exist "${HOMEDIR}/${user}/web/${domain}/public_html/${webpath}"
        fi
    fi

    # Test HTTP
    # Curl hates UTF domains so convert them to ascci.
    domain_idn=$(idn2 $domain)
    run curl --location --silent --show-error --insecure --resolve "${domain_idn}:80:${domain_ip}" "http://${domain_idn}/${webpath}"
    assert_success
    assert_output --partial "$webproof"

    # Test HTTPS
    if [ "$SSL" = "yes" ]; then
        run v-list-web-domain-ssl $user $domain
        assert_success

        run curl --location --silent --show-error --insecure --resolve "${domain_idn}:443:${domain_ip}" "https://${domain_idn}/${webpath}"
        assert_success
        assert_output --partial "$webproof"
    fi
}

function validate_headers_domain() {
  local user=$1
  local domain=$2
  local webproof=$3

  refute [ -z "$user" ]
  refute [ -z "$domain" ]
  refute [ -z "$webproof" ]

  source $HESTIA/func/ip.sh

  run v-list-web-domain $user $domain
  assert_success

  USER_DATA=$HESTIA/data/users/$user
  local domain_ip=$(get_object_value 'web' 'DOMAIN' "$domain" '$IP')
  SSL=$(get_object_value 'web' 'DOMAIN' "$domain" '$SSL')
  domain_ip=$(get_real_ip "$domain_ip")

  # Test HTTP with  code redirect for some reasons due to 301 redirect it fails
  curl -i --resolve "${domain}:80:${domain_ip}" "http://${domain}"
  assert_success
  assert_output --partial "$webproof"

}

function validate_mail_domain() {
    local user=$1
    local domain=$2

    refute [ -z "$user" ]
    refute [ -z "$domain" ]

    run v-list-mail-domain $user $domain
    assert_success

    assert_dir_exist $HOMEDIR/$user/mail/$domain
    assert_dir_exist $HOMEDIR/$user/conf/mail/$domain
    assert_file_exist $HOMEDIR/$user/conf/mail/$domain/aliases
    if [ -n "$ANTISPAM_SYSTEM" ]; then
      assert_file_exist $HOMEDIR/$user/conf/mail/$domain/antispam
    fi
    if [ -n "$ANTIVIRUS_SYSTEM" ]; then
      assert_file_exist $HOMEDIR/$user/conf/mail/$domain/antivirus
    fi
    assert_file_exist $HOMEDIR/$user/conf/mail/$domain/fwd_only
    assert_file_exist $HOMEDIR/$user/conf/mail/$domain/ip
    assert_file_exist $HOMEDIR/$user/conf/mail/$domain/passwd
}

function validate_webmail_domain() {
    local user=$1
    local domain=$2
    local webproof=$3
    local webpath=${4}

    refute [ -z "$user" ]
    refute [ -z "$domain" ]
    refute [ -z "$webproof" ]

    source $HESTIA/func/ip.sh

    USER_DATA=$HESTIA/data/users/$user
    local domain_ip=$(get_object_value 'web' 'DOMAIN' "$domain" '$IP')
    SSL=$(get_object_value 'mail' 'DOMAIN' "$domain" '$SSL')
    domain_ip=$(get_real_ip "$domain_ip")

    if [ ! -z "$webpath" ]; then
        assert_file_exist /var/lib/roundcube/$webpath
    fi

    if [ "$SSL" = "no" ]; then
        # Test HTTP
        run curl --location --silent --show-error --insecure  --resolve "webmail.${domain}:80:${domain_ip}" "http://webmail.${domain}/${webpath}"
        assert_success
        assert_output --partial "$webproof"

        # Test HTTP
        run curl  --location --silent --show-error --insecure --resolve "mail.${domain}:80:${domain_ip}" "http://mail.${domain}/${webpath}"
        assert_success
        assert_output --partial "$webproof"
    fi

    # Test HTTPS
    if [ "$SSL" = "yes" ]; then
        # Test HTTP with 301 redirect for some reasons due to 301 redirect it fails
        run curl --silent --show-error --insecure --resolve "webmail.${domain}:80:${domain_ip}" "http://webmail.${domain}/${webpath}"
        assert_success
        assert_output --partial "301 Moved Permanently"

        # Test HTTP with 301 redirect for some reasons due to 301 redirect it fails
        run curl --silent --show-error --insecure --resolve "mail.${domain}:80:${domain_ip}" "http://mail.${domain}/${webpath}"
        assert_success
        assert_output --partial "301 Moved Permanently"

        run v-list-mail-domain-ssl $user $domain
        assert_success

        run curl --location --silent --show-error --insecure --resolve "webmail.${domain}:443:${domain_ip}" "https://webmail.${domain}/${webpath}"
        assert_success
        assert_output --partial "$webproof"

        run curl --location --silent --show-error --insecure --resolve "mail.${domain}:443:${domain_ip}" "https://mail.${domain}/${webpath}"
        assert_success
        assert_output --partial "$webproof"
    fi
}

function validate_database(){
    local type=$1
    local database=$2
    local dbuser=$3
    local password=$4

    host_str=$(grep "HOST='localhost'" $HESTIA/conf/$type.conf)
    parse_object_kv_list "$host_str"
    if [ -z $PORT ]; then PORT=3306; fi

    refute [ -z "$HOST" ]
    refute [ -z "$PORT" ]
    refute [ -z "$database" ]
    refute [ -z "$dbuser" ]
    refute [ -z "$password" ]


    if [ "$type" = "mysql" ]; then
      # Create an connection to verify correct username / password has been set correctly
      tmpfile=$(mktemp /tmp/mysql.XXXXXX)
      echo "[client]">$tmpfile
      echo "host='$HOST'" >> $tmpfile
      echo "user='$dbuser'" >> $tmpfile
      echo "password='$password'" >> $tmpfile
      echo "port='$PORT'" >> $tmpfile
      chmod 600 $tmpfile

      sql_tmp=$(mktemp /tmp/query.XXXXXX)
      echo "show databases;" > $sql_tmp
      run mysql --defaults-file=$tmpfile < "$sql_tmp"

      assert_success
      assert_output --partial "$database"

      rm -f "$sql_tmp"
      rm -f "$tmpfile"
    else

      echo "*:*:*:$dbuser:$password" > /root/.pgpass
      chmod 600 /root/.pgpass
      run export PGPASSWORD="$password" | psql -h $HOST -U "$dbuser" -p $PORT -d "$database" --no-password  -c "\l"
      assert_success
      rm /root/.pgpass
    fi
}

function check_ip_banned(){
  local ip=$1
  local chain=$2

  run grep "IP='$ip' CHAIN='$chain'" $HESTIA/data/firewall/banlist.conf
  assert_success
  assert_output --partial "$ip"
}

function check_ip_not_banned(){
  local ip=$1
  local chain=$2
  run grep "IP='$ip' CHAIN='$chain'" $HESTIA/data/firewall/banlist.conf
  assert_failure E_ARGS
  refute_output
}


#----------------------------------------------------------#
#                           IP                             #
#----------------------------------------------------------#

@test "RDNS: Check reverse Dns validation" {
    # 1. PTR record for a IP should return a hostname(reverse) which in turn must resolve to the same IP addr(forward). (Full circle)
    #  `-> not implemented in `is_ip_rdns_valid` yet and also not tested here
    # 2. Reject rPTR records that match generic dynamic IP pool patterns

    local ip="54.200.1.22"
    local rdns="ec2-54-200-1-22.us-west-2.compute.amazonaws.com"
    run is_ip_rdns_valid "$ip"
    assert_failure
    refute_output

    local rdns="ec2.54.200.1.22.us-west-2.compute.amazonaws.com"
    run is_ip_rdns_valid "$ip"
    assert_failure
    refute_output

    local rdns="ec2-22-1-200-54.us-west-2.compute.amazonaws.com"
    run is_ip_rdns_valid "$ip"
    assert_failure
    refute_output

    local rdns="ec2.22.1.200.54.us-west-2.compute.amazonaws.com"
    run is_ip_rdns_valid "$ip"
    assert_failure
    refute_output

    local rdns="ec2-200-54-1-22.us-west-2.compute.amazonaws.com"
    run is_ip_rdns_valid "$ip"
    assert_failure
    refute_output

    local rdns="panel-22.mydomain.tld"
    run is_ip_rdns_valid "$ip"
    assert_success
    assert_output "$rdns"

    local rdns="mail.mydomain.tld"
    run is_ip_rdns_valid "$ip"
    assert_success
    assert_output "$rdns"

    local rdns="mydomain.tld"
    run is_ip_rdns_valid "$ip"
    assert_success
    assert_output "$rdns"

}

#----------------------------------------------------------#
#                         User                             #
#----------------------------------------------------------#

@test "User: Add new user" {
    run v-add-user $user $user $user@hestiacp.com default "Super Test"
    assert_success
    refute_output
}

@test "User: Add new user Failed 1" {
	run v-add-user 'jäap' $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}
@test "User: Add new user Failed 2" {
	run v-add-user 'ëaap' $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}

@test "User: Add new user Failed 3" {
	run v-add-user 'jaaẞ'  $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}

@test "User: Add new user Failed 4" {
	run v-add-user '1234'  $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}

@test "User: Add new user Failed 5" {
	run v-add-user '1aap'  $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}

@test "User: Add new user Failed 6" {
	run v-add-user 'ib_Buffer'  $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: The user name'
}

@test "User: Add new user Failed 7" {
	run v-add-user 'hello.com'  $user $user@hestiacp2.com default "Super Test"
	assert_failure $E_INVALID
	assert_output --partial 'Error: invalid user format'
}


@test "User: Add new user Success 1" {
	run v-add-user 'jaap01'  $user $user@hestiacp2.com default "Super Test"
	assert_success
	refute_output
}

@test "User: Add new user Success 1 Delete" {
	run v-delete-user jaap01
	assert_success
	refute_output
}

@test "User: Add new user Success 2" {
	run v-add-user 'buffer'  $user $user@hestiacp2.com default "Super Test"
	assert_success
	refute_output
}

@test "User: Add new user Success 2 Delete" {
	run v-delete-user buffer
	assert_success
	refute_output
}

@test "User: Change user password" {
    run v-change-user-password "$user" "$userpass2"
    assert_success
    refute_output
}

@test "User: Change user email" {
    run v-change-user-contact "$user" tester@hestiacp.com
    assert_success
    refute_output
}

@test "User: Change user contact invalid email " {
    run v-change-user-contact "$user" testerhestiacp.com
    assert_failure $E_INVALID
    assert_output --partial 'Error: invalid email format'
}

@test "User: Change user name" {
    run v-change-user-name "$user" "New name"
    assert_success
    refute_output
}

@test "User: Change user shell" {
    run v-change-user-shell $user bash
    assert_success
    refute_output

    run stat -c '%U' /home/$user
    assert_output --partial "$user"
		mount_file=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home")
		assert_file_not_exist /etc/systemd/system/$mount_file
}

@test "User: Change user invalid shell" {
    run v-change-user-shell $user bashinvalid
    assert_failure $E_INVALID
    assert_output --partial 'shell bashinvalid is not valid'
}

@test "User: Change user nologin" {
    run v-change-user-shell $user nologin
    assert_success
    refute_output

    run stat -c '%U' /home/$user
    assert_output --partial 'root'
		mount_file=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home/$user")
		assert_file_exist /etc/systemd/system/$mount_file
}

@test "User: Change user bash with bubblewrap jail" {
    run v-change-user-shell $user jailbash
    assert_success
    refute_output

    run stat -c '%U' /home/$user
    assert_output --partial "$user"
		mount_file=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home")
		assert_file_not_exist /etc/systemd/system/$mount_file
}

@test "User: Change user default ns" {
    run v-change-user-ns $user ns0.com ns1.com ns2.com ns3.com
    assert_success
    refute_output

    run v-list-user-ns "$user" plain
    assert_success
    assert_output --partial 'ns0.com'
}

@test "User: Change user language" {
  run v-change-user-language $user "nl"
  assert_success
  refute_output
}

@test "User: Change user language (Does not exists)" {
  run v-change-user-language $user "aa"
  assert_failure $E_NOTEXIST
}

@test "User: Change user sort order" {
  run v-change-user-sort-order $user "name"
  assert_success
  refute_output
}

@test "User: Change user theme" {
  run v-change-user-theme $user "flat"
  assert_success
  refute_output
}

@test "User: Change user theme (Does not exists)" {
  run v-change-user-theme $user "aa"
  assert_failure $E_NOTEXIST
}

@test "User: Change user login ip" {
  run v-change-user-config-value $user "LOGIN_USE_IPLIST" "1.2.3.4,1.2.3.5"
  assert_success
  refute_output
}

@test "User: Change user login ip (Failed)" {
  run v-change-user-config-value $user "LOGIN_USE_IPLIST" "'; echo 'jaap'; echo '"
  assert_failure $E_INVALID
}

@test "User: Add user notification" {
  run v-add-user-notification $user "Test message" "Message"
  assert_success
  refute_output
}
@test "User: Acknowledge user notification" {
  run v-acknowledge-user-notification $user 1
  assert_success
  refute_output
}
@test "User: List user notification" {
  run v-list-user-notifications $user csv
  assert_success
  assert_output --partial "1,\"Test message\",\"Message\",yes"
}
@test "User: Delete user notification" {
  run v-delete-user-notification admin 1
  assert_success
  refute_output
}

@test "User: Get User salt ipv4" {
  run v-get-user-salt $user 192.168.2.10
  assert_success
}

@test "User: Get User salt ipv4 invalid" {
  run v-get-user-salt $user 192.168.992.10
  assert_failure $E_INVALID
}

@test "User: Get User salt ipv6" {
  run v-get-user-salt $user "21DA:D3:0:2F3B:2AA:FF:FE28:9C5A"
  assert_success
}

@test "User: Get User salt ipv6 not exists" {
  run v-get-user-salt "notexists" "21DA:D3:0:2F3B:2AA:FF:FE28:9C5B"
  assert_failure $E_PASSWORD
}

@test "User: Get User salt ipv6 invalid" {
  run v-get-user-salt "$user" "21DA:D3:0:2F3B:ZZZ:FF:FE28:9C5B"
  assert_failure $E_INVALID
}

@test "User: Check user password" {
  run v-check-user-password $user "$userpass2" 192.168.2.10 'no'
  assert_success
}

@test "User: Check user password Incorrect password" {
  run v-check-user-password $user "$userpass1" 192.168.2.10 'no'
  assert_failure $E_PASSWORD
}

@test "User: Check user hash ipv4" {
  hash=$(v-check-user-password $user "$userpass2" 192.168.2.10 'yes');
  run v-check-user-hash $user $hash 192.168.2.10
  assert_success
}

@test "User: Check user hash ipv6" {
  hash=$(v-check-user-password $user "$userpass2" 21DA:D3:0:2F3B:2AA:FF:FE28:9C5A 'yes');
  run v-check-user-hash $user $hash 21DA:D3:0:2F3B:2AA:FF:FE28:9C5A
  assert_success
}

@test "User: Check user hash ipv6 incorrect" {
  run v-check-user-hash $user 'jafawefaweijawe' 21DA:D3:0:2F3B:2AA:FF:FE28:9C5A
  assert_failure $E_PASSWORD
}

#----------------------------------------------------------#
#                         Cron                             #
#----------------------------------------------------------#

@test "Cron: Add cron job" {
    run v-add-cron-job $user 1 1 1 1 1 echo
    assert_success
    refute_output
}

@test "Cron: Suspend cron job" {
    run v-suspend-cron-job $user 1
    assert_success
    refute_output
}

@test "Cron: Unsuspend cron job" {
    run v-unsuspend-cron-job $user 1
    assert_success
    refute_output
}

@test "Cron: Delete cron job" {
    run v-delete-cron-job $user 1
    assert_success
    refute_output
}

@test "Cron: Add cron job (duplicate)" {
    run v-add-cron-job $user 1 1 1 1 1 echo 1
    assert_success
    refute_output

    run v-add-cron-job $user 1 1 1 1 1 echo 1
    assert_failure $E_EXISTS
    assert_output --partial 'JOB=1 already exists'
}

@test "Cron: Second cron job" {
    run v-add-cron-job $user 2 2 2 2 2 echo 2
    assert_success
    refute_output
}

@test "Cron: Two cron jobs must be listed" {
    run v-list-cron-jobs $user csv
    assert_success
    assert_line --partial '1,1,1,1,1,"ZWNobw==",no'
    assert_line --partial '2,2,2,2,2,"ZWNobw==",no'
}

@test "Cron: rebuild" {
    run v-rebuild-cron-jobs $user
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                          IP                              #
#----------------------------------------------------------#

@test "Ip: Add new ip on first interface" {
    interface=$(v-list-sys-interfaces plain | head -n 1)
    run ip link show dev $interface
    assert_success

    local a2_rpaf="/etc/$WEB_SYSTEM/mods-enabled/rpaf.conf"
    local a2_remoteip="/etc/$WEB_SYSTEM/mods-enabled/remoteip.conf"

    # Save initial state
    echo "interface=${interface}" >> /tmp/hestia-test-env.sh
    [ -f "$a2_rpaf" ]     && file_hash1=$(cat $a2_rpaf     |md5sum |cut -d" " -f1) && echo "a2_rpaf_hash='${file_hash1}'"     >> /tmp/hestia-test-env.sh
    [ -f "$a2_remoteip" ] && file_hash2=$(cat $a2_remoteip |md5sum |cut -d" " -f1) && echo "a2_remoteip_hash='${file_hash2}'" >> /tmp/hestia-test-env.sh


    local ip="198.18.0.12"
    run v-add-sys-ip $ip 255.255.255.255 $interface $user
    assert_success
    refute_output

    assert_file_exist /etc/$WEB_SYSTEM/conf.d/$ip.conf
    assert_file_exist $HESTIA/data/ips/$ip
    assert_file_contains $HESTIA/data/ips/$ip "OWNER='$user'"
    assert_file_contains $HESTIA/data/ips/$ip "INTERFACE='$interface'"

    if [ -n "$PROXY_SYSTEM" ]; then
        assert_file_exist /etc/$PROXY_SYSTEM/conf.d/$ip.conf
        [ -f "$a2_rpaf" ] && assert_file_contains "$a2_rpaf" "RPAFproxy_ips.*$ip\b"
        [ -f "$a2_remoteip" ] && assert_file_contains "$a2_remoteip" "RemoteIPInternalProxy $ip\$"
    fi

}

@test "Ip: [Ubuntu] Netplan file updated" {
   # Skip if Debian
   if [ $(lsb_release -s -i) != "Ubuntu" ]; then
   skip
   fi

   # Test will fail if systemd (For example Proxmox) is used for setting ip addresses. How ever there is no "decent" way to check if Netplan is used except via the method used in v-add-sys-ip and there for breaking the reason to test this. How ever if the test used in v-add-sys-ip fails it still should check if it exists!

   assert_file_exist /etc/netplan/60-hestia.yaml

   # also check if file contains the newly added ip
   assert_file_contains /etc/netplan/60-hestia.yaml "$ip"
}

@test "Ip: [Debian] Netplan file updated" {
   # Skip with netplan
   if [ $(lsb_release -s -i) = "Ubuntu" ]; then
	 skip
	 fi

   assert_file_exist  /etc/network/interfaces
   assert_file_contains  /etc/network/interfaces "$ip"
}

@test "Ip: Add ip (duplicate)" {
    run v-add-sys-ip 198.18.0.12 255.255.255.255 $interface $user
    assert_failure $E_EXISTS
}

@test "Ip: Add extra ip" {
    local ip="198.18.0.121"
    run v-add-sys-ip $ip 255.255.255.255 $interface $user
    assert_success
    refute_output

    assert_file_exist /etc/$WEB_SYSTEM/conf.d/$ip.conf
    assert_file_exist $HESTIA/data/ips/$ip
    assert_file_contains $HESTIA/data/ips/$ip "OWNER='$user'"
    assert_file_contains $HESTIA/data/ips/$ip "INTERFACE='$interface'"

    if [ -n "$PROXY_SYSTEM" ]; then
        assert_file_exist /etc/$PROXY_SYSTEM/conf.d/$ip.conf
        local a2_rpaf="/etc/$WEB_SYSTEM/mods-enabled/rpaf.conf"
        [ -f "$a2_rpaf" ] && assert_file_contains "$a2_rpaf" "RPAFproxy_ips.*$ip\b"

        local a2_remoteip="/etc/$WEB_SYSTEM/mods-enabled/remoteip.conf"
        [ -f "$a2_remoteip" ] && assert_file_contains "$a2_remoteip" "RemoteIPInternalProxy $ip\$"
    fi
}

@test "Ip: Delete ip 198.18.0.12" {
    local ip="198.18.0.12"
    run v-delete-sys-ip $ip
    assert_success
    refute_output

    assert_file_not_exist /etc/$WEB_SYSTEM/conf.d/$ip.conf
    assert_file_not_exist $HESTIA/data/ips/$ip
}

@test "Ip: [Ubuntu] Netplan file changed" {
	 # Skip if Debian
	 if [ $(lsb_release -s -i) != "Ubuntu" ]; then
	 skip
	 fi

	 ip="198.18.0.121"
	 assert_file_exist /etc/netplan/60-hestia.yaml
	 assert_file_contains /etc/netplan/60-hestia.yaml "$ip"
}

@test "Ip: Delete ip 198.18.0.121" {
	ip="198.18.0.121"
	run v-delete-sys-ip $ip
	assert_success
	refute_output

	assert_file_not_exist /etc/$WEB_SYSTEM/conf.d/$ip.conf
	assert_file_not_exist $HESTIA/data/ips/$ip

	if [ -n "$PROXY_SYSTEM" ]; then
			assert_file_not_exist /etc/$PROXY_SYSTEM/conf.d/$ip.conf
	fi

	# remoteip and rpaf config hashes must match the initial one
	if [ ! -z "$a2_rpaf_hash" ]; then
			local a2_rpaf="/etc/$WEB_SYSTEM/mods-enabled/rpaf.conf"
			file_hash=$(cat $a2_rpaf |md5sum |cut -d" " -f1)
			assert_equal "$file_hash" "$a2_rpaf_hash"
	fi
	if [ ! -z "$a2_remoteip_hash" ]; then
			local a2_remoteip="/etc/$WEB_SYSTEM/mods-enabled/remoteip.conf"
			file_hash=$(cat $a2_remoteip |md5sum |cut -d" " -f1)
			assert_equal "$file_hash" "$a2_remoteip_hash"
	fi
}

@test "Ip: Add IP for rest of the test" {
    local ip="198.18.0.125"
    run v-add-sys-ip $ip 255.255.255.255 $interface $user
    assert_success
    refute_output

    assert_file_exist /etc/$WEB_SYSTEM/conf.d/$ip.conf
    assert_file_exist $HESTIA/data/ips/$ip
    assert_file_contains $HESTIA/data/ips/$ip "OWNER='$user'"
    assert_file_contains $HESTIA/data/ips/$ip "INTERFACE='$interface'"

    if [ -n "$PROXY_SYSTEM" ]; then
        assert_file_exist /etc/$PROXY_SYSTEM/conf.d/$ip.conf
        local a2_rpaf="/etc/$WEB_SYSTEM/mods-enabled/rpaf.conf"
        [ -f "$a2_rpaf" ] && assert_file_contains "$a2_rpaf" "RPAFproxy_ips.*$ip\b"

        local a2_remoteip="/etc/$WEB_SYSTEM/mods-enabled/remoteip.conf"
        [ -f "$a2_remoteip" ] && assert_file_contains "$a2_remoteip" "RemoteIPInternalProxy $ip\$"
    fi
}

#----------------------------------------------------------#
#                         WEB                              #
#----------------------------------------------------------#

@test "WEB: Add web domain" {
    run v-add-web-domain $user $domain 198.18.0.125
    assert_success
    refute_output

    echo -e "<?php\necho 'Hestia Test:'.(4*3);" > $HOMEDIR/$user/web/$domain/public_html/php-test.php
    validate_web_domain $user $domain 'Hestia Test:12' 'php-test.php'
    rm $HOMEDIR/$user/web/$domain/public_html/php-test.php
}

@test "WEB: Add web domain (duplicate)" {
    run v-add-web-domain $user $domain 198.18.0.125
    assert_failure $E_EXISTS
}

@test "WEB: Add web domain alias" {
    run v-add-web-domain-alias $user $domain v3.$domain
    assert_success
    refute_output
}

@test "WEB: Add web domain alias (duplicate)" {
    run v-add-web-domain-alias $user $domain v3.$domain
    assert_failure $E_EXISTS
}

@test "WEB: Add web domain wildcard alias" {
    run v-add-web-domain-alias $user $domain "*.$domain"
    assert_success
    refute_output
}

@test "WEB: Delete web domain wildcard alias" {
    run v-delete-web-domain-alias $user $domain "*.$domain"
    assert_success
    refute_output
}

@test "WEB: Add web domain stats" {
    run v-add-web-domain-stats $user $domain awstats
    assert_success
    refute_output
}

@test "WEB: Add web domain stats user" {
    skip
    run v-add-web-domain-stats-user $user $domain test m3g4p4ssw0rd
    assert_success
    refute_output
}

@test "WEB: Suspend web domain" {
    run v-suspend-web-domain $user $domain
    assert_success
    refute_output

	echo -e "<?php\necho 'Hestia Test:'.(4*3);" > $HOMEDIR/$user/web/$domain/public_html/php-test.php
    validate_web_domain $user $domain 'This site is currently suspended'
	validate_web_domain $user $domain 'This site is currently suspended' 'php-test.php'
	rm $HOMEDIR/$user/web/$domain/public_html/php-test.php
}

@test "WEB: Unsuspend web domain" {
    run v-unsuspend-web-domain $user $domain
    assert_success
    refute_output

    echo -e "<?php\necho 'Hestia Test:'.(4*3);" > $HOMEDIR/$user/web/$domain/public_html/php-test.php
    validate_web_domain $user $domain 'Hestia Test:12' 'php-test.php'
    rm $HOMEDIR/$user/web/$domain/public_html/php-test.php
}

@test "WEB: Add redirect to www.domain.com" {
    run v-add-web-domain-redirect $user $domain www.$domain 301
    assert_success
    refute_output

    run validate_headers_domain $user $domain "301"
}

@test "WEB: Delete redirect to www.domain.com" {
    run v-delete-web-domain-redirect $user $domain
    assert_success
    refute_output
}

@test "WEB: Enable Fast CGI Cache" {
    if [ "$WEB_SYSTEM" != "nginx" ]; then
      skip "FastCGI cache is not supported"
    fi

    run v-add-fastcgi-cache $user $domain '1m' yes
    assert_success
    refute_output

    echo -e "<?php\necho 'Hestia Test:'.(4*3);" > $HOMEDIR/$user/web/$domain/public_html/php-test.php
    run validate_headers_domain $user $domain "Miss"
    run validate_headers_domain $user $domain "Hit"
    rm $HOMEDIR/$user/web/$domain/public_html/php-test.php
}

@test "WEB: Disable Fast CGI Cache" {
    if [ "$WEB_SYSTEM" != "nginx" ]; then
      skip "FastCGI cache is not supported"
    fi
    run v-delete-fastcgi-cache $user $domain yes
    assert_success
    refute_output
}


@test "WEB: Generate Self signed certificate" {
    ssl=$(v-generate-ssl-cert "$domain" "info@$domain" US CA "Orange County" HestiaCP IT "mail.$domain" | tail -n1 | awk '{print $2}')
    echo $ssl;
    mv $ssl/$domain.crt /tmp/$domain.crt
    mv $ssl/$domain.key /tmp/$domain.key
}

@test "WEB: Add ssl" {
    # Use self signed certificates during last test
    run v-add-web-domain-ssl $user $domain /tmp
    assert_success
    refute_output
}

@test "WEB: Rebuild web domain" {
    run v-rebuild-web-domains $user
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                         IDN                              #
#----------------------------------------------------------#

@test "WEB: Add IDN domain UTF idn-tést.eu" {
   run v-add-web-domain $user idn-tést.eu 198.18.0.125
   assert_success
   refute_output
	 assert_file_exist /home/$user/web/idn-tést.eu/public_html/index.html
}

@test "WEB: Add IDN domain ASCII idn-tést.eu" {
   # Expected to fail due to utf exists
   run v-add-web-domain $user "xn--idn-tst-fya.eu" 198.18.0.125
   assert_failure $E_EXISTS
}


@test "WEB: Generate Self signed certificate ASCII idn-tést.eu" {
    run v-generate-ssl-cert "xn--idn-tst-fya.eu" "info@xn--idn-tst-fya.eu" US CA "Orange County" HestiaCP IT "mail.xn--idn-tst-fya.eu"
    assert_success
}


@test "WEB: Delete IDN domain idn-tést.eu" {
   run v-delete-web-domain $user idn-tést.eu
   assert_success
   refute_output
}

@test "WEB: Add IDN domain UTF bløst.рф" {
   run v-add-web-domain $user bløst.рф 198.18.0.125
   assert_success
   refute_output
}

@test "WEB: Generate Self signed certificate ASCII bløst.рф" {
    run v-generate-ssl-cert "xn--blst-hra.xn--p1ai" "info@xn--blst-hra.xn--p1ai" US CA "Orange County" HestiaCP IT "mail.xn--blst-hra.xn--p1ai"
    assert_success
}

@test "WEB: Delete IDN domain bløst.рф" {
 run v-delete-web-domain $user bløst.рф
 assert_success
 refute_output
}

#----------------------------------------------------------#
#                      MULTIPHP                            #
#----------------------------------------------------------#

@test "Multiphp: Default php Backend version" {
    def_phpver=$(multiphp_default_version)
    multi_domain="multiphp.${domain}"

    run v-add-web-domain $user $multi_domain 198.18.0.125
    assert_success
    refute_output

    echo -e "<?php\necho PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "$def_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"

}

@test "Multiphp: Change backend version - PHP v5.6" {
    test_phpver='5.6'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-5_6' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v7.0" {
    test_phpver='7.0'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-7_0' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v7.1" {
    test_phpver='7.1'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-7_1' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v7.2" {
    test_phpver='7.2'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-7_2' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v7.3" {
    test_phpver='7.3'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-7_3' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v7.4" {
    test_phpver='7.4'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-7_4' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
}

@test "Multiphp: Change backend version - PHP v8.0" {
    test_phpver='8.0'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-8_0' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm $HOMEDIR/$user/web/$multi_domain/public_html/php-test.php
}

@test "Multiphp: Change backend version - PHP v8.1" {
    test_phpver='8.1'
    multi_domain="multiphp.${domain}"

    if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
        skip "PHP ${test_phpver} not installed"
    fi

    run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-8_1' 'yes'
    assert_success
    refute_output

    # Changing web backend will create a php-fpm pool config in the corresponding php folder
    assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

    # A single php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '1'

    echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
    validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
    rm $HOMEDIR/$user/web/$multi_domain/public_html/php-test.php
}

@test "Multiphp: Change backend version - PHP v8.2" {
	test_phpver='8.2'
	multi_domain="multiphp.${domain}"

	if [ ! -d "/etc/php/${test_phpver}/fpm/pool.d/" ]; then
		skip "PHP ${test_phpver} not installed"
	fi

	run v-change-web-domain-backend-tpl $user $multi_domain 'PHP-8_2' 'yes'
	assert_success
	refute_output

	# Changing web backend will create a php-fpm pool config in the corresponding php folder
	assert_file_exist "/etc/php/${test_phpver}/fpm/pool.d/${multi_domain}.conf"

	# A single php-fpm pool config file must be present
	num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
	assert_equal "$num_fpm_config_files" '1'

	echo -e "<?php\necho 'hestia-multiphptest:'.PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" > "$HOMEDIR/$user/web/$multi_domain/public_html/php-test.php"
	validate_web_domain $user $multi_domain "hestia-multiphptest:$test_phpver" 'php-test.php'
	rm $HOMEDIR/$user/web/$multi_domain/public_html/php-test.php
}

@test "Multiphp: Cleanup" {
    multi_domain="multiphp.${domain}"

    run v-delete-web-domain $user $multi_domain 'yes'
    assert_success
    refute_output

    # No php-fpm pool config file must be present
    num_fpm_config_files="$(find -L /etc/php/ -name "${multi_domain}.conf" | wc -l)"
    assert_equal "$num_fpm_config_files" '0'
}


#----------------------------------------------------------#
#                     CUSTOM DOCROOT                       #
#----------------------------------------------------------#

@test "Docroot: Self Subfolder" {
    docroot1_domain="docroot1.${domain}"

    run v-add-web-domain $user $docroot1_domain 198.18.0.125
    assert_success
    refute_output

    run v-add-fs-directory $user "$HOMEDIR/$user/web/$docroot1_domain/public_html/public/"
    assert_success
    refute_output

    run v-change-web-domain-docroot $user "$docroot1_domain" "$docroot1_domain" "/public"
    assert_success
    refute_output

    echo -e '<?php\necho "self-sub-".$_SERVER["HTTP_HOST"];' > "$HOMEDIR/$user/web/$docroot1_domain/public_html/public/php-test.php"
    validate_web_domain $user $docroot1_domain "self-sub-${docroot1_domain}" 'php-test.php'
    rm "$HOMEDIR/$user/web/$docroot1_domain/public_html/public/php-test.php"
}

@test "Docroot: Other domain subfolder" {
    docroot1_domain="docroot1.${domain}"
    docroot2_domain="docroot2.${domain}"

    run v-add-web-domain $user $docroot2_domain 198.18.0.125
    assert_success
    refute_output

    run v-add-fs-directory $user "$HOMEDIR/$user/web/$docroot2_domain/public_html/public/"
    assert_success
    refute_output

    run v-change-web-domain-docroot $user "$docroot1_domain" "$docroot2_domain" "/public"
    assert_success
    refute_output

    echo -e '<?php\necho "doc2-sub-".$_SERVER["HTTP_HOST"];' > "$HOMEDIR/$user/web/$docroot2_domain/public_html/public/php-test.php"
    validate_web_domain $user $docroot1_domain "doc2-sub-${docroot1_domain}" 'php-test.php'
    rm "$HOMEDIR/$user/web/$docroot2_domain/public_html/public/php-test.php"
}

@test "Docroot: Other domain root folder" {
    docroot1_domain="docroot1.${domain}"
    docroot2_domain="docroot2.${domain}"

    run v-change-web-domain-docroot $user "$docroot1_domain" "$docroot2_domain"
    assert_success
    refute_output

    echo -e '<?php\necho "doc2-root-".$_SERVER["HTTP_HOST"];' > "$HOMEDIR/$user/web/$docroot2_domain/public_html/php-test.php"
    validate_web_domain $user $docroot1_domain "doc2-root-${docroot1_domain}" 'php-test.php'
    rm "$HOMEDIR/$user/web/$docroot2_domain/public_html/php-test.php"
}

@test "Docroot: Reset" {
    docroot1_domain="docroot1.${domain}"

    run v-change-web-domain-docroot $user "$docroot1_domain" "default"
    assert_success
    refute_output

    echo -e '<?php\necho "doc1-root-".$_SERVER["HTTP_HOST"];' > "$HOMEDIR/$user/web/$docroot1_domain/public_html/php-test.php"
    validate_web_domain $user $docroot1_domain "doc1-root-${docroot1_domain}" 'php-test.php'
    rm "$HOMEDIR/$user/web/$docroot1_domain/public_html/php-test.php"
}

@test "Docroot: Cleanup" {
    docroot1_domain="docroot1.${domain}"
    docroot2_domain="docroot2.${domain}"

    run v-delete-web-domain $user $docroot1_domain
    assert_success
    refute_output

    run v-delete-web-domain $user $docroot2_domain
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                         DNS                              #
#----------------------------------------------------------#

@test "DNS: Add domain" {
    run v-add-dns-domain $user $domain 198.18.0.125
    assert_success
    refute_output
}

@test "DNS: Add domain (duplicate)" {
    run v-add-dns-domain $user $domain 198.18.0.125
    assert_failure $E_EXISTS
}

@test "DNS: Add domain record" {
    run v-add-dns-record $user $domain test A 198.18.0.125 '' 30
    assert_success
    refute_output
}

@test "DNS: Add domain record *.domain.com" {
    run v-add-dns-record $user $domain '*' A 198.18.0.125 '' 40
    assert_success
    refute_output
}

@test "DNS: Add domain record *.domain.com with ID 0" {
		run v-add-dns-record $user $domain '*' A 198.18.0.125 '' 0
		assert_failure $E_INVALID
}

@test "DNS: Change DNS record" {
  run v-change-dns-record $user $domain 30 test A 198.18.0.125 "" "" 1500
  assert_success
  refute_output
}

@test "DNS: Change DNS record (no update)" {
  run v-change-dns-record $user $domain 30 test A 198.18.0.125 "" "" 1500
  assert_failure $E_EXSIST
}

@test "DNS: Change DNS record id" {
  run v-change-dns-record-id $user $domain 30 31
  assert_success
  refute_output
  # Change back
  run v-change-dns-record-id $user $domain 31 30
}

@test "DNS: Change DNS record id (no update)" {
  run v-change-dns-record-id  $user $domain 30 30
  assert_failure $E_EXSIST
}

@test "DNS: Delete domain record" {
    run v-delete-dns-record $user $domain 30
    assert_success
    refute_output
}

@test "DNS: Delete missing domain record" {
    run v-delete-dns-record $user $domain 30
    assert_failure $E_NOTEXIST
}

@test "DNS: Change domain expire date" {
    run v-change-dns-domain-exp $user $domain 2020-01-01
    assert_success
    refute_output
}

@test "DNS: Add domain record MX" {
    run v-add-dns-record $user $domain '@' MX mx.hestiacp.com  '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestiacp.com."

    run v-change-dns-record $user $domain 50 '@' MX mx.hestia.com
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestia.com."

    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Add domain record NS" {
    run v-delete-dns-record $user $domain 50
    run v-add-dns-record $user $domain '@' NS mx.hestiacp.com  '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestiacp.com."

    run v-change-dns-record $user $domain 50 '@' NS mx.hestia.com
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestia.com."

    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Add domain record SRV" {
    run v-delete-dns-record $user $domain 50
    run v-add-dns-record $user $domain '_test_domain' SRV mx.hestiacp.com  '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestiacp.com."

    run v-change-dns-record $user $domain 50 '_test.domain' SRV mx.hestia.com
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestia.com."

    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Add domain record CNAME" {
    run v-delete-dns-record $user $domain 50
    run v-add-dns-record $user $domain 'mail' CNAME mx.hestiacp.com  '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestiacp.com."

    run v-change-dns-record $user $domain 50 'mail' CNAME mx.hestia.com
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "mx.hestia.com."

    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Check txt dns records type1" {
    [ -z "$DNS_SYSTEM" ] && skip

    run v-delete-dns-record $user $domain 50

    record1_in='v=DMARC1; p=quarantine; pct=100'
    record2_in='v=DMARC1; p=quarantine; pct=90'

    record1_out='"v=DMARC1; p=quarantine; pct=100"'
    record2_in='"v=DMARC1; p=quarantine; pct=90"'

    # Test Create
    run v-add-dns-record $user $domain 'test-long-txt' 'TXT' "$record1_in" '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "$record1_out"

    # Test Edit
    run v-change-dns-record $user $domain 50 'test-long-txt' 'TXT' "$record2_in"
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "$record2_out"

    # Test Cleanup
    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Check txt dns records type2" {
    [ -z "$DNS_SYSTEM" ] && skip

    run v-delete-dns-record $user $domain 50

    record3_in='k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4+VEVsoTbl6tYLJlhozqAGju3IgpSVdBAS5LMyzpHP8/L0/PlyVRJnm2xECjVk3DRqCmelyIvmraw1VtFz2aH6DRlDhHsZghj1DmGhwN+7NkwIb4hEvmytMVAz1WyiLH6Rm6Iemm/ZCt1RhrAMUYLxHA9mJgky76YCcf8/cX35xC+1vd4a5U6YofAZeVP9DBvVgQ8ung4gVrOrQrXkU8QfVNAoXz5pfJo74GB7woIBFhZXsU6SKho7KnzT5inVCIOtWp7L5hyEnbySWQPHT2vAMCCAe2AY/Vv0N3HW14o8P3b4A6OU920wFB2kA7pkQNzO5OwH+HSttwG0PaIiQxYQIDAQAB'
    record3_out='"k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4+VEVsoTbl6tYLJlhozqAGju3IgpSVdBAS5LMyzpHP8/L0/PlyVRJnm2xECjVk3DRqCmelyIvmraw1VtFz2aH6DRlDhHsZghj1DmGhwN+7NkwIb4hEvmytMVAz1WyiLH6Rm6Iemm/ZCt1RhrAMUYLxHA9mJgky76YCcf8/cX35xC+1vd4a5U6YofAZeVP9DBvVgQ8ung4g""VrOrQrXkU8QfVNAoXz5pfJo74GB7woIBFhZXsU6SKho7KnzT5inVCIOtWp7L5hyEnbySWQPHT2vAMCCAe2AY/Vv0N3HW14o8P3b4A6OU920wFB2kA7pkQNzO5OwH+HSttwG0PaIiQxYQIDAQAB"'

    record4_in='k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4+VEVsoTbl6tYLJlhozqAGju3IgpSVdBAS5LMyzpHP8/L0/PlyVRJnm2xECjVk3DRqCmelyIvmraw1VtFz2aH6DRlDhHsZghj1DmGhwN+7NkwIb4hEvmytMVAz1WyiLH6Rm6Iemm/ZCt1RhrAMUYLxHA9mJgky76YCcf8/cX35xC+1vd4a5U6YofAZeVP9DBvVgQ8ung4gVrOrQrXkU8QfVNAoXz5pfJo74GB7woIBFhZXsU6SKho7KnzT5inVCIOtWp7L5hyEnbySWQPHT2vAMCCAe2AY/Vv0N3HW14o8P3b4A6OU920wFB2kA7pkQNzO5OwH+HSttwG0PaIiQxYQIDAQA4'
    record4_out='"k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4+VEVsoTbl6tYLJlhozqAGju3IgpSVdBAS5LMyzpHP8/L0/PlyVRJnm2xECjVk3DRqCmelyIvmraw1VtFz2aH6DRlDhHsZghj1DmGhwN+7NkwIb4hEvmytMVAz1WyiLH6Rm6Iemm/ZCt1RhrAMUYLxHA9mJgky76YCcf8/cX35xC+1vd4a5U6YofAZeVP9DBvVgQ8ung4g""VrOrQrXkU8QfVNAoXz5pfJo74GB7woIBFhZXsU6SKho7KnzT5inVCIOtWp7L5hyEnbySWQPHT2vAMCCAe2AY/Vv0N3HW14o8P3b4A6OU920wFB2kA7pkQNzO5OwH+HSttwG0PaIiQxYQIDAQA4"'

    # Test Create
    run v-add-dns-record $user $domain 'test-long-txt' 'TXT' "$record3_in" '' 50
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "$record3_out"

    # Test Edit
    run v-change-dns-record $user $domain 50 'test-long-txt' 'TXT' "$record4_in"
    assert_success
    refute_output

    assert_file_contains "$HOMEDIR/$user/conf/dns/${domain}.db" "$record4_out"

    # Test Cleanup
    run v-delete-dns-record $user $domain 50
    assert_success
    refute_output
}

@test "DNS: Change domain ip" {
    run v-change-dns-domain-ip $user $domain 127.0.0.1
    assert_success
    refute_output
}

@test "DNS: Suspend domain" {
    run v-suspend-dns-domain $user $domain
    assert_success
    refute_output
}

@test "DNS: Unsuspend domain" {
    run v-unsuspend-dns-domain $user $domain
    assert_success
    refute_output
}

@test "DNS: Rebuild" {
    run v-rebuild-dns-domains $user
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                         MAIL                             #
#----------------------------------------------------------#

@test "MAIL: Add domain" {
    run v-add-mail-domain $user $domain
    assert_success
    refute_output

    validate_mail_domain $user $domain
}

@test "MAIL: Add mail domain webmail client (Roundcube)" {
    run v-add-mail-domain-webmail $user $domain "roundcube" "yes"
    assert_success
    refute_output

    # echo -e "<?php\necho 'Server: ' . \$_SERVER['SERVER_SOFTWARE'];" > /var/lib/roundcube/check_server.php
    validate_webmail_domain $user $domain 'Welcome to Roundcube Webmail'
    # rm /var/lib/roundcube/check_server.php
}

@test "Mail: Add SSL to mail domain" {
    # Use generated certificates during WEB Generate Self signed certificate
    run v-add-mail-domain-ssl $user $domain /tmp
    assert_success
    refute_output

    validate_webmail_domain $user $domain 'Welcome to Roundcube Webmail'
}

@test "MAIL: Add mail domain webmail client (SnappyMail)" {
    if [ -z "$(echo $WEBMAIL_SYSTEM | grep -w "snappymail")" ]; then
        skip "Webmail client SnappyMail not installed"
    fi
    run v-add-mail-domain-webmail $user $domain "snappymail" "yes"
    assert_success
    refute_output
    validate_mail_domain $user $domain

    validate_webmail_domain $user $domain 'SnappyMail Webmail'
}

@test "MAIL: Disable webmail client" {
    run v-add-mail-domain-webmail $user $domain "disabled" "yes"
    assert_success
    refute_output
    validate_mail_domain $user $domain

    validate_webmail_domain $user $domain 'Success!'

    run v-add-mail-domain-webmail $user $domain "roundcube" "yes"
    assert_success
    refute_output
}

@test "MAIL: Add domain (duplicate)" {
    run v-add-mail-domain $user $domain
    assert_failure $E_EXISTS
}

@test "MAIL: Add account" {
    run v-add-mail-account $user $domain test "$userpass2"
    assert_success
    assert_file_contains /etc/exim4/domains/$domain/limits "test@$domain"
    refute_output
}

@test "MAIL: Add account (duplicate)" {
	run v-add-mail-account $user $domain test "$userpass2"
	assert_failure $E_EXISTS
}

@test "MAIL: Add account 2" {
	run v-add-mail-account $user $domain random "$userpass2"
	assert_success
	assert_file_contains  /etc/exim4/domains/$domain/limits "random@$domain"
	refute_output
}

@test "MAIL: Add account alias" {
	run v-add-mail-account-alias $user $domain test hestiacprocks
	assert_success
	assert_file_contains /etc/exim4/domains/$domain/aliases "hestiacprocks@$domain"
	refute_output
}

@test "MAIL: Add account alias 2" {
	run v-add-mail-account-alias $user $domain test hestiacprocks2
	assert_success
	assert_file_contains /etc/exim4/domains/$domain/aliases "hestiacprocks2@$domain"
	refute_output
}

@test "MAIL: Add account alias 3" {
	run v-add-mail-account-alias $user $domain test hestiacp
	assert_success
	assert_file_contains /etc/exim4/domains/$domain/aliases "hestiacp@$domain"
	refute_output
}

@test "MAIL: Add account 3" {
	run v-add-mail-account $user $domain hestia "$userpass2"
	assert_success
	assert_file_contains /etc/exim4/domains/$domain/limits "hestia@$domain"
	refute_output
}

@test "MAIL: Add account 4" {
	run v-add-mail-account $user $domain hestiarocks3 "$userpass2"
	assert_success
	assert_file_contains /etc/exim4/domains/$domain/limits "hestiarocks3@$domain"
	refute_output
}

@test "MAIL: Add account 5" {
		run v-add-mail-account $user $domain 01 "$userpass2"
		assert_success
		assert_file_contains /etc/exim4/domains/$domain/limits "01@$domain"
		refute_output
}

@test "MAIL: Add account 6" {
		run v-add-mail-account $user $domain "0aa" "$userpass2"
		assert_success
		assert_file_contains /etc/exim4/domains/$domain/limits "0aa@$domain"
		refute_output
}

@test "MAIL: Add account alias Invalid length" {
	run v-add-mail-account-alias $user $domain test 'hestiacp-really-rocks-but-i-want-to-have-feature-xyz-and-i-want-it-now'
	assert_failure $E_INVALID
}
@test "MAIL: Add account alias Invalid" {
	run v-add-mail-account-alias $user $domain test 'test+123'
	assert_failure $E_INVALID
}
@test "MAIL: Add account alias starting with -" {
	run v-add-mail-account-alias $user $domain test '-test'
	assert_success
}
@test "MAIL: Add account alias ending with -" {
	run v-add-mail-account-alias $user $domain test 'test-'
	assert_success
}
@test "MAIL: Add account alias Invalid 2" {
	run v-add-mail-account-alias $user $domain test 'hestia@test'
	assert_failure $E_INVALID
}

@test "MAIL: Add account alias (duplicate)" {
	run v-add-mail-account-alias $user $domain test hestiacprocks
	assert_failure $E_EXISTS
}

@test "MAIL: change mail account password" {
  run curl -k -X POST -d "email=test@$domain&password=$userpass2&new=123456" https://localhost:8083/reset/mail/
  assert_success
  assert_output --partial "==ok=="
}

@test "MAIL: change mail account password (Incorrect PW)" {
  run curl -k -X POST -d "email=test@$domain&password=$userpass2&new=123456" https://localhost:8083/reset/mail/
  assert_success
  assert_output --partial "error"
}

@test "MAIL: Change rate limit" {
    run v-change-mail-account-rate-limit $user $domain test 10
    assert_file_contains /etc/exim4/domains/$domain/limits "test@$domain:10"
}

@test "MAIL: Delete account" {
    run v-delete-mail-account $user $domain test
    assert_success
    refute_output
}

@test "MAIL: Delete missing account" {
    run v-delete-mail-account $user $domain test
    assert_failure $E_NOTEXIST
}

@test "MAIL: Rebuild mail domain" {
    run v-rebuild-mail-domains $user
    assert_success
    refute_output
}

@test "MAIL: Delete DKIM" {
    run v-delete-mail-domain-dkim $user $domain
    assert_success
    refute_output

    run grep "RECORD='_domainkey'" "${HESTIA}/data/users/${user}/dns/${domain}.conf"
    assert_failure
    refute_output

    run grep "RECORD='mail._domainkey'" "${HESTIA}/data/users/${user}/dns/${domain}.conf"
    assert_failure
    refute_output
}

@test "MAIL: Add DKIM" {
    run v-add-mail-domain-dkim $user $domain
    assert_success
    refute_output

    run grep "RECORD='_domainkey'" "${HESTIA}/data/users/${user}/dns/${domain}.conf"
    assert_success
    assert_output --partial "RECORD='_domainkey' TYPE='TXT'"

    run grep "RECORD='mail._domainkey'" "${HESTIA}/data/users/${user}/dns/${domain}.conf"
    assert_success
    assert_output  --partial "RECORD='mail._domainkey' TYPE='TXT'"
}

@test "MAIL: Delete DKIM but preserve custom dkim records" {
    run v-add-dns-record $user $domain 'k2._domainkey' 'TXT' 'v=DKIM1; k=rsa; p=123456'
    assert_success
    refute_output

    run v-delete-mail-domain-dkim $user $domain
    assert_success
    refute_output

    run grep "RECORD='k2._domainkey'" "${HESTIA}/data/users/${user}/dns/${domain}.conf"
    assert_success
    assert_output --partial "RECORD='k2._domainkey' TYPE='TXT'"
}


#----------------------------------------------------------#
#    Limit possibilities adding different owner domain     #
#----------------------------------------------------------#

@test "Allow Users: User can't add user.user2.com " {
    # Case: admin company.tld
    # users should not be allowed to add user.company.tld
    run v-add-user $user2 $user2 $user@hestiacp.com default "Super Test"
    assert_success
    refute_output

    run v-add-web-domain $user2 $rootdomain
    assert_success
    refute_output

    run v-add-web-domain $user $subdomain
    assert_failure $E_EXISTS
}

@test "Allow Users: User can't add user.user2.com as alias" {
    run v-add-web-domain-alias $user $domain $subdomain
    assert_failure $E_EXISTS
}

@test "Allow Users: User can't add user.user2.com as mail domain" {
    run v-add-mail-domain $user $subdomain
    assert_failure $E_EXISTS
}

@test "Allow Users: User can't add user.user2.com as dns domain" {
    run v-add-dns-domain $user $subdomain 198.18.0.125
    assert_failure $E_EXISTS
}

@test "Allow Users: Set Allow users" {
    # Allow user to yes allows
    # Case: admin company.tld
    # users are allowed to add user.company.tld
    run v-add-web-domain-allow-users $user2 $rootdomain
    assert_success
    refute_output
}

@test "Allow Users: User can add user.user2.com" {
    run v-add-web-domain $user $subdomain
    assert_success
    refute_output
}

@test "Allow Users: User can add user.user2.com as alias" {
    run v-delete-web-domain $user $subdomain
    assert_success
    refute_output

    run v-add-web-domain-alias $user $domain $subdomain
    assert_success
    refute_output
}

@test "Allow Users: User can add user.user2.com as mail domain" {
    run v-add-mail-domain $user $subdomain
    assert_success
    refute_output
}

@test "Allow Users: User can add user.user2.com as dns domain" {
    run v-add-dns-domain $user $subdomain 198.18.0.125
    assert_success
    refute_output
}

@test "Allow Users: Cleanup tests" {
    run v-delete-dns-domain $user $subdomain
    assert_success
    refute_output

    run v-delete-mail-domain $user $subdomain
    assert_success
    refute_output
}


@test "Allow Users: Set Allow users no" {
    run v-delete-web-domain-alias $user $domain $subdomain
    assert_success
    refute_output

    run v-delete-web-domain-allow-users $user2 $rootdomain
    assert_success
    refute_output
}

@test "Allow Users: User can't add user.user2.com again" {
    run v-add-web-domain $user $subdomain
    assert_failure $E_EXISTS
}

@test "Allow Users: user2 can add user.user2.com again" {
    run v-add-web-domain $user2 $subdomain
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                         DB                               #
#----------------------------------------------------------#

@test "MYSQL: Add database" {
    run v-add-database $user database dbuser 1234 mysql
    assert_success
    refute_output
    # validate_database mysql database_name database_user password
    validate_database mysql $database $dbuser 1234
}

@test "MYSQL: Add Database (Duplicate)" {
    run v-add-database $user database dbuser 1234 mysql
    assert_failure $E_EXISTS
}

@test "MYSQL: Rebuild Database" {
    run v-rebuild-database $user $database
    assert_success
    refute_output
}

@test "MYSQL: Change database user password" {
    run v-change-database-password $user $database 123456
    assert_success
    refute_output

    validate_database mysql $database $dbuser 123456
}

@test "MYSQL: Change database user" {
    run v-change-database-user $user $database database
    assert_success
    refute_output
    validate_database mysql $database $database 123456
}

@test "MYSQL: Suspend database" {
    run v-suspend-database $user $database
    assert_success
    refute_output
}

@test "MYSQL: Unsuspend database" {
    run v-unsuspend-database $user $database
    assert_success
    refute_output
}

@test "MYSQL: Delete database" {
    run v-delete-database $user $database
    assert_success
    refute_output
}

@test "MYSQL: Delete missing database" {
    run v-delete-database $user $database
    assert_failure $E_NOTEXIST
}

@test "PGSQL: Add database invalid user" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-add-database "$user" "database" "dbuser" "1234ABCD" "pgsql"
  assert_failure $E_INVALID
}

@test "PGSQL: Add database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-add-user $pguser $pguser $user@hestiacp.com default "Super Test"
  run v-add-database "$pguser" "database" "dbuser" "1234ABCD" "pgsql"
  assert_success
  refute_output
  # validate_database pgsql $pgdatabase $pgdbuser "1234ABCD"
}

@test "PGSQL: Add Database (Duplicate)" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-add-database "$pguser" "database" "dbuser" "1234ABCD" "pgsql"
  assert_failure $E_EXISTS
}

@test "PGSQL: Rebuild Database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-rebuild-database $pguser $pgdatabase
  assert_success
  refute_output
}

@test "PGSQL: Change database user password" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-change-database-password $pguser $pgdatabase "123456"
  assert_success
  refute_output

  # validate_database pgsql $pgdatabase $pgdbuser "123456"
}

@test "PGSQL: Suspend database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-suspend-database $pguser $pgdatabase
  assert_success
  refute_output
}

@test "PGSQL: Unsuspend database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-unsuspend-database $pguser $pgdatabase
  assert_success
  refute_output
}

@test "PGSQL: Change database user" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  skip
  run v-change-database-user $pguser $pgdatabase database
  assert_success
  refute_output
  validate_database pgsql $pgdatabase $pgdatabase 123456
}


@test "PGSQL: Delete database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-delete-database $pguser $pgdatabase
  assert_success
  refute_output
}

@test "PGSQL: Delete missing database" {
  if [ -z "$(echo $DB_SYSTEM | grep -w "pgsql")" ]; then
    skip "PostGreSQL is not installed"
  fi
  run v-delete-database $pguser $pgdatabase
  assert_failure $E_NOTEXIST
  run v-delete-user $pguser
}

#----------------------------------------------------------#
#                         System                           #
#----------------------------------------------------------#
@test "System: Set/Enable SMTP account for internal mail" {
  run v-add-sys-smtp $domain 587 STARTTLS info@$domain 1234-test noreply@$domain
  assert_success
  refute_output
}

@test "System: Disable SMTP account for internal mail" {
  run v-delete-sys-smtp
  assert_success
  refute_output
}

@test "System: Set/Enable SMTP relay" {
  run v-add-sys-smtp-relay $domain info@$domain 1234-test 587
  assert_success
  refute_output
  assert_file_exist /etc/exim4/smtp_relay.conf
}

@test "System: Delete SMTP relay" {
  run v-delete-sys-smtp-relay
  assert_success
  refute_output
  assert_file_not_exist /etc/exim4/smtp_relay.conf
}

#----------------------------------------------------------#
#                        Firewall                          #
#----------------------------------------------------------#

@test "Firewall: Add ip to banlist" {
  run v-add-firewall-ban '1.2.3.4' 'HESTIA'
  assert_success
  refute_output

  check_ip_banned '1.2.3.4' 'HESTIA'
}

@test "Firewall: Delete ip to banlist" {
  run v-delete-firewall-ban '1.2.3.4' 'HESTIA'
  assert_success
  refute_output
  check_ip_not_banned '1.2.3.4' 'HESTIA'
}

@test "Firewall: Add ip to banlist for ALL" {
  run v-add-firewall-ban '1.2.3.4' 'HESTIA'
  assert_success
  refute_output
  run v-add-firewall-ban '1.2.3.4' 'MAIL'
  assert_success
  refute_output
  check_ip_banned '1.2.3.4' 'HESTIA'
}

@test "Firewall: Delete ip to banlist CHAIN = ALL" {
  run v-delete-firewall-ban '1.2.3.4' 'ALL'
  assert_success
  refute_output
  check_ip_not_banned '1.2.3.4' 'HESTIA'
}

@test "Test Whitelist Fail2ban" {

echo   "1.2.3.4" >> $HESTIA/data/firewall/excludes.conf
  run v-add-firewall-ban '1.2.3.4' 'HESTIA'
  rm $HESTIA/data/firewall/excludes.conf
  check_ip_not_banned '1.2.3.4' 'HESTIA'
}

@test "Test create ipset" {
  run v-add-firewall-ipset "country-nl" "https://raw.githubusercontent.com/ipverse/rir-ip/master/country/nl/ipv4-aggregated.txt" v4 yes
  assert_success
  refute_output
}

@test "Create firewall with Ipset" {
  run v-add-firewall-rule 'DROP' 'ipset:country-nl' '8083,22' 'TCP' 'Test'
  assert_success
  refute_output
}

@test "List firewall rules" {
  run v-list-firewall csv
  assert_success
  assert_line --partial '11,DROP,TCP,8083,22,ipset:country-nl'

}

@test "Delete firewall with Ipset" {
  run v-delete-firewall-rule '11'
  assert_success
  refute_output
}

@test "Test delete ipset" {
  run v-delete-firewall-ipset "country-nl"
  assert_success
  refute_output
}

#----------------------------------------------------------#
#                         PACKAGE                          #
#----------------------------------------------------------#

@test "Package: Create new Package" {
    cp $HESTIA/data/packages/default.pkg /tmp/package
    run v-add-user-package /tmp/package hestiatest
    assert_success
    refute_output
}

@test "Package: Assign user to new Package" {
    run v-change-user-package  $user hestiatest
    assert_success
    refute_output
}

@test "Package: Create new package (Duplicate)" {
    sed -i "s/BANDWIDTH='unlimited'/BANDWIDTH='100'/g" /tmp/package
    run v-add-user-package /tmp/package hestiatest
    assert_failure $E_EXISTS
}

@test "Package: Update new Package" {
    sed -i "s/BANDWIDTH='unlimited'/BANDWIDTH='100'/g" /tmp/package
    run v-add-user-package /tmp/package hestiatest yes
    assert_success
    refute_output
}

@test "Package: Update package of user" {
    run v-change-user-package  $user hestiatest
    assert_success
    refute_output
    run grep "BANDWIDTH='100'" $HESTIA/data/users/$user/user.conf
    assert_success
    assert_output --partial "100"
}

@test "Package: Copy package Not Exists" {
  run v-copy-user-package hestiadoesnotexists hestiatest2
  assert_failure $E_NOTEXIST
}

@test "Package: Copy package" {
  run v-copy-user-package hestiatest hestiatest2
  assert_success
  refute_output
}

@test "Package: Copy package Exists" {
  run v-copy-user-package hestiatest hestiatest2
  assert_failure $E_EXISTS
}

@test "Package: Delete package" {
    run v-delete-user-package hestiatest
    run v-delete-user-package hestiatest2
    rm /tmp/package
    assert_success
    refute_output
    run grep "BANDWIDTH='unlimited'" $HESTIA/data/users/$user/user.conf
    assert_success
    assert_output --partial "unlimited"
}

#----------------------------------------------------------#
#                         Backup user                      #
#----------------------------------------------------------#

@test "Backup: Backup user" {
  run v-backup-user $user
  assert_success
}

@test "Backup: List Backups" {
  run v-list-user-backups $user plain
  assert_success
  assert_output --partial "$user"
}

@test "Backup: Delete backups" {
  run v-delete-user-backup $user $(v-list-user-backups $user plain | cut -f1)
  assert_success
  run rm /backup/$user.log
}

#----------------------------------------------------------#
#                  Change owner scripts                    #
#----------------------------------------------------------#

@test "Change: Change domain owner" {
    run v-change-domain-owner $domain $user2
    assert_success

    run v-restart-web
    run v-restart-proxy

}

@test "Change: Add database" {
    run v-add-database $user database dbuser 1234 mysql
    assert_success
    refute_output
    # validate_database mysql database_name database_user password
    validate_database mysql $database $dbuser 1234
}

@test "Change: Change database owner" {
    run v-change-database-owner $database $user2
    assert_success
    validate_database mysql test-5286_database test-5286_dbuser 1234
}

@test "Change: Delete database" {
    run v-delete-database $user2 test-5286_database
    assert_success
    refute_output
}

#----------------------------------------------------------#
#                         CLEANUP                          #
#----------------------------------------------------------#

@test "Mail: Delete domain" {
    run v-delete-mail-domain $user2 $domain
    assert_success
    refute_output
}

@test "DNS: Delete domain" {
    run v-delete-dns-domain $user2 $domain
    assert_success
    refute_output
}

@test "WEB: Delete domain" {
    run v-delete-web-domain $user2 $domain
    assert_success
    refute_output
}

@test "Delete user" {
    run v-delete-user $user
    assert_success
    refute_output
}

@test "Delete user2" {
    run v-delete-user $user2
    assert_success
    refute_output
}



@test "Ip: Delete the test IP" {
    run v-delete-sys-ip 198.18.0.125
    assert_success
    refute_output
}

@test 'assert()' {
  touch '/var/log/test.log'
  assert [ -e '/var/log/test.log' ]
}
