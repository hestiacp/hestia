#!/bin/bash

#===========================================================================#
#                                                                           #
# Hestia Control Panel - Domain Function Library                            #
#                                                                           #
#===========================================================================#

#----------------------------------------------------------#
#                        WEB                               #
#----------------------------------------------------------#

# Web template check
is_web_template_valid() {
	if [ -n "$WEB_SYSTEM" ]; then
		tpl="$WEBTPL/$WEB_SYSTEM/$WEB_BACKEND/$1.tpl"
		stpl="$WEBTPL/$WEB_SYSTEM/$WEB_BACKEND/$1.stpl"
		if [ ! -e "$tpl" ] || [ ! -e "$stpl" ]; then
			check_result "$E_NOTEXIST" "$1 web template doesn't exist"
		fi
	fi
}

# Proxy template check
is_proxy_template_valid() {
	if [ -n "$PROXY_SYSTEM" ]; then
		tpl="$WEBTPL/$PROXY_SYSTEM/$1.tpl"
		stpl="$WEBTPL/$PROXY_SYSTEM/$1.stpl"
		if [ ! -e "$tpl" ] || [ ! -e "$stpl" ]; then
			check_result "$E_NOTEXIST" "$1 proxy template doesn't exist"
		fi
	fi
}

# Backend template check
is_backend_template_valid() {
	if [ -n "$WEB_BACKEND" ]; then
		if [ ! -e "$WEBTPL/$WEB_BACKEND/$1.tpl" ]; then
			check_result "$E_NOTEXIST" "$1 backend template doesn't exist"
		fi
	fi
}

# Web domain existence check
is_web_domain_new() {
	web=$(grep -F -H "DOMAIN='$1'" $HESTIA/data/users/*/web.conf)
	if [ -n "$web" ]; then
		if [ "$type" == 'web' ]; then
			check_result "$E_EXISTS" "Web domain $1 exists"
		fi
		web_user=$(echo "$web" | cut -f 7 -d /)
		if [ "$web_user" != "$user" ]; then
			check_result "$E_EXISTS" "Web domain $1 exists"
		fi
	fi
}

# Web alias existence check
is_web_alias_new() {
	grep -wH "$1" $HESTIA/data/users/*/web.conf | while read -r line; do
		user=$(echo $line | cut -f 7 -d /)
		string=$(echo $line | cut -f 2- -d ':')
		parse_object_kv_list $string
		if [ -n "$ALIAS" ]; then
			a1=$(echo "'$ALIAS'" | grep -F "'$1'")
			if [ -n "$a1" ] && [ "$2" == "web" ]; then
				return "$E_EXISTS"
			fi
			if [ -n "$a1" ] && [ "$user" != "$user" ]; then
				return "$E_EXISTS"
			fi
			a2=$(echo "'$ALIAS'" | grep -F "'$1,")
			if [ -n "$a2" ] && [ "$2" == "web" ]; then
				return "$E_EXISTS"
			fi
			if [ -n "$a2" ] && [ "$user" != "$user" ]; then
				return "$E_EXISTS"
			fi
			a3=$(echo "'$ALIAS'" | grep -F ",$1,")
			if [ -n "$a3" ] && [ "$2" == "web" ]; then
				return "$E_EXISTS"
			fi
			if [ -n "$a3" ] && [ "$user" != "$user" ]; then
				return "$E_EXISTS"
			fi
			a4=$(echo "'$ALIAS'" | grep -F ",$1'")
			if [ -n "$a4" ] && [ "$2" == "web" ]; then
				return "$E_EXISTS"
			fi
			if [ -n "$a4" ] && [ "$user" != "$user" ]; then
				return "$E_EXISTS"
			fi
		fi
	done
	if [ $? -ne 0 ]; then
		check_result "$E_EXISTS" "Web alias $1 exists"
	fi
}

# Prepare web backend
prepare_web_backend() {
	# Accept first function argument as backend template otherwise fallback to $template global variable
	local backend_template=${1:-$template}

	pool=$(find -L /etc/php/ -name "$domain.conf" -exec dirname {} \;)
	# Check if multiple-PHP installed
	regex="socket-(\d+)_(\d+)"
	if [[ $backend_template =~ ^.*PHP-([0-9])\_([0-9])$ ]]; then
		backend_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
		pool=$(find -L /etc/php/$backend_version -type d \( -name "pool.d" -o -name "*fpm.d" \))
	else
		backend_version=$(multiphp_default_version)
		if [ -z "$pool" ] || [ -z "$BACKEND" ]; then
			pool=$(find -L /etc/php/$backend_version -type d \( -name "pool.d" -o -name "*fpm.d" \))
		fi
	fi

	if [ ! -e "$pool" ]; then
		check_result $E_NOTEXIST "php-fpm pool doesn't exist"
	fi
	backend_type="$domain"
	if [ "$WEB_BACKEND_POOL" = 'user' ]; then
		backend_type="$user"
	fi
	if [ -e "$pool/$backend_type.conf" ]; then
		backend_lsnr=$(grep "listen =" $pool/$backend_type.conf)
		backend_lsnr=$(echo "$backend_lsnr" | cut -f 2 -d = | sed "s/ //")
		if [ -n "$(echo $backend_lsnr | grep /)" ]; then
			backend_lsnr="unix:$backend_lsnr"
		fi
	fi
}

# Delete web backend
delete_web_backend() {
	find -L /etc/php/ -type f -name "$backend_type.conf" -exec rm -f {} \;
}

# Prepare web aliases
prepare_web_aliases() {
	i=1
	for tmp_alias in ${1//,/ }; do
		tmp_alias_idn="$tmp_alias"
		if [[ "$tmp_alias" = *[![:ascii:]]* ]]; then
			tmp_alias_idn=$(idn2 --quiet $tmp_alias)
		fi
		if [[ $i -eq 1 ]]; then
			aliases="$tmp_alias"
			aliases_idn="$tmp_alias_idn"
			alias_string="ServerAlias $tmp_alias_idn"
		else
			aliases="$aliases,$tmp_alias"
			aliases_idn="$aliases_idn,$tmp_alias_idn"
			if (($i % 100 == 0)); then
				alias_string="$alias_string\n    ServerAlias $tmp_alias_idn"
			else
				alias_string="$alias_string $tmp_alias_idn"
			fi
		fi
		alias_number=$i
		((i++))
	done
}

# Update web domain values
prepare_web_domain_values() {
	if [[ "$domain" = *[![:ascii:]]* ]]; then
		domain_idn=$(idn2 --quiet $domain)
	else
		domain_idn=$domain
	fi
	group="$user"
	docroot="$HOMEDIR/$user/web/$domain/public_html"
	sdocroot="$docroot"
	if [ "$SSL_HOME" = 'single' ]; then
		sdocroot="$HOMEDIR/$user/web/$domain/public_shtml"
		$BIN/v-add-fs-directory "$user" "$HOMEDIR/$user/web/$domain/public_shtml"
		chmod 751 $HOMEDIR/$user/web/$domain/public_shtml
		chown www-data:$user $HOMEDIR/$user/web/$domain/public_shtml
	fi

	if [ -n "$WEB_BACKEND" ]; then
		prepare_web_backend "$BACKEND"
	fi

	server_alias=''
	alias_string=''
	aliases_idn=''
	ssl_ca_str=''
	prepare_web_aliases $ALIAS

	ssl_crt="$HOMEDIR/$user/conf/web/$domain/ssl/$domain.crt"
	ssl_key="$HOMEDIR/$user/conf/web/$domain/ssl/$domain.key"
	ssl_pem="$HOMEDIR/$user/conf/web/$domain/ssl/$domain.pem"
	ssl_ca="$HOMEDIR/$user/conf/web/$domain/ssl/$domain.ca"
	if [ ! -e "$USER_DATA/ssl/$domain.ca" ]; then
		ssl_ca_str='#'
	fi

	# Set correct document root
	if [ -n "$CUSTOM_DOCROOT" ]; then
		# Custom document root has been set by the user, import from configuration
		custom_docroot="$CUSTOM_DOCROOT"
		docroot="$custom_docroot"
		sdocroot="$docroot"
	elif [ -n "$CUSTOM_DOCROOT" ] && [ -n "$target_directory" ]; then
		# Custom document root has been specified with a different target than public_html
		if [ -d "$HOMEDIR/$user/web/$target_domain/public_html/$target_directory/" ]; then
			custom_docroot="$HOMEDIR/$user/web/$target_domain/public_html/$target_directory"
			docroot="$custom_docroot"
			sdocroot="$docroot"
		fi
	elif [ -n "$CUSTOM_DOCROOT" ] && [ -z "$target_directory" ]; then
		# Set custom document root to target domain's public_html folder
		custom_docroot="$HOMEDIR/$user/web/$target_domain/public_html"
		docroot="$custom_docroot"
		sdocroot="$docroot"
	else
		# No custom document root specified, use default
		docroot="$HOMEDIR/$user/web/$domain/public_html"
		sdocroot="$docroot"
	fi

	if [ "$SUSPENDED" = 'yes' ]; then
		docroot="$HESTIA/data/templates/web/suspend"
		sdocroot="$HESTIA/data/templates/web/suspend"
		if [ "$PROXY_SYSTEM" == "nginx" ]; then
			PROXY="suspended"
		else
			TPL="suspended"
		fi
	fi
}

# Add web config
add_web_config() {
	# Check if folder already exists
	if [ ! -d "$HOMEDIR/$user/conf/web/$domain" ]; then
		mkdir -p "$HOMEDIR/$user/conf/web/$domain/"
	fi

	conf="$HOMEDIR/$user/conf/web/$domain/$1.conf"
	if [[ "$2" =~ stpl$ ]]; then
		conf="$HOMEDIR/$user/conf/web/$domain/$1.ssl.conf"
	fi

	domain_idn=$domain
	format_domain_idn

	WEBTPL_LOCATION="$WEBTPL/$1"
	if [ "$1" != "$PROXY_SYSTEM" ] && [ -n "$WEB_BACKEND" ] && [ -d "$WEBTPL_LOCATION/$WEB_BACKEND" ]; then
		if [ -f "$WEBTPL_LOCATION/$WEB_BACKEND/$2" ]; then
			# check for backend specific template
			WEBTPL_LOCATION="$WEBTPL/$1/$WEB_BACKEND"
		fi
	fi

	# Note: Removing or renaming template variables will lead to broken custom templates.
	#   -If possible custom templates should be automatically upgraded to use the new format
	#   -Alternatively a depreciation period with proper notifications should be considered

	cat "${WEBTPL_LOCATION}/$2" \
		| sed -e "s|%ip%|$local_ip|g" \
			-e "s|%domain%|$domain|g" \
			-e "s|%domain_idn%|$domain_idn|g" \
			-e "s|%alias%|${aliases//,/ }|g" \
			-e "s|%alias_idn%|${aliases_idn//,/ }|g" \
			-e "s|%alias_string%|$alias_string|g" \
			-e "s|%email%|info@$domain|g" \
			-e "s|%web_system%|$WEB_SYSTEM|g" \
			-e "s|%web_port%|$WEB_PORT|g" \
			-e "s|%web_ssl_port%|$WEB_SSL_PORT|g" \
			-e "s|%backend_lsnr%|$backend_lsnr|g" \
			-e "s|%rgroups%|$WEB_RGROUPS|g" \
			-e "s|%proxy_system%|$PROXY_SYSTEM|g" \
			-e "s|%proxy_port%|$PROXY_PORT|g" \
			-e "s|%proxy_url%|$PROXY_URL|g" \
			-e "s|%proxy_ssl_port%|$PROXY_SSL_PORT|g" \
			-e "s/%proxy_extentions%/${PROXY_EXT//,/|}/g" \
			-e "s/%proxy_extensions%/${PROXY_EXT//,/|}/g" \
			-e "s|%user%|$user|g" \
			-e "s|%group%|$user|g" \
			-e "s|%home%|$HOMEDIR|g" \
			-e "s|%docroot%|$docroot|g" \
			-e "s|%sdocroot%|$sdocroot|g" \
			-e "s|%ssl_crt%|$ssl_crt|g" \
			-e "s|%ssl_key%|$ssl_key|g" \
			-e "s|%ssl_pem%|$ssl_pem|g" \
			-e "s|%ssl_ca_str%|$ssl_ca_str|g" \
			-e "s|%ssl_ca%|$ssl_ca|g" \
			> $conf

	process_http2_directive "$conf"

	chown root:$user $conf
	chmod 640 $conf

	if [[ "$2" =~ stpl$ ]]; then
		rm -f /etc/$1/conf.d/domains/$domain.ssl.conf
		ln -s $conf /etc/$1/conf.d/domains/$domain.ssl.conf

		# Rename/Move extra SSL config files
		find=$(find $HOMEDIR/$user/conf/web/*.$domain.org* 2> /dev/null)
		for f in $find; do
			if [[ $f =~ .*/s(nginx|apache2)\.$domain\.conf(.*) ]]; then
				ServerType="${BASH_REMATCH[1]}"
				CustomConfigName="${BASH_REMATCH[2]}"
				if [ "$CustomConfigName" = "_letsencrypt" ]; then
					rm -f "$f"
					continue
				fi
				mv "$f" "$HOMEDIR/$user/conf/web/$domain/$ServerType.ssl.conf_old$CustomConfigName"
			fi
		done
	else
		rm -f /etc/$1/conf.d/domains/$domain.conf
		ln -s $conf /etc/$1/conf.d/domains/$domain.conf
		# Rename/Move extra config files
		find=$(find $HOMEDIR/$user/conf/web/*.$domain.org* 2> /dev/null)
		for f in $find; do
			if [[ $f =~ .*/(nginx|apache2)\.$domain\.conf(.*) ]]; then
				ServerType="${BASH_REMATCH[1]}"
				CustomConfigName="${BASH_REMATCH[2]}"
				if [ "$CustomConfigName" = "_letsencrypt" ]; then
					rm -f "$f"
					continue
				fi
				mv "$f" "$HOMEDIR/$user/conf/web/$domain/$ServerType.conf_old$CustomConfigName"
			elif [[ $f =~ .*/forcessl\.(nginx|apache2)\.$domain\.conf ]]; then
				ServerType="${BASH_REMATCH[1]}"
				mv "$f" "$HOMEDIR/$user/conf/web/$domain/$ServerType.forcessl.conf"
			fi
		done
	fi

	trigger="${2/.*pl/.sh}"
	if [ -x "${WEBTPL_LOCATION}/$trigger" ]; then
		$WEBTPL_LOCATION/$trigger \
			$user $domain $local_ip $HOMEDIR \
			$HOMEDIR/$user/web/$domain/public_html
	fi
}

# Get config top and bottom line number
get_web_config_lines() {
	tpl_lines=$(egrep -ni "name %domain_idn%" $1 | grep -w %domain_idn%)
	tpl_lines=$(echo "$tpl_lines" | cut -f 1 -d :)
	tpl_last_line=$(wc -l $1 | cut -f 1 -d ' ')
	if [ -z "$tpl_lines" ]; then
		check_result $E_PARSING "can't parse template $1"
	fi

	domain_idn=$domain
	format_domain_idn
	vhost_lines=$(grep -niF "name $domain_idn" $2)
	vhost_lines=$(echo "$vhost_lines" | egrep "$domain_idn($| |;)")
	vhost_lines=$(echo "$vhost_lines" | cut -f 1 -d :)
	if [ -z "$vhost_lines" ]; then
		check_result $E_PARSING "can't parse config $2"
	fi

	top_line=$((vhost_lines + 1 - tpl_lines))
	bottom_line=$((top_line - 1 + tpl_last_line))
	multi=$(sed -n "$top_line,$bottom_line p" $2 | grep ServerAlias | wc -l)
	if [ "$multi" -ge 2 ]; then
		bottom_line=$((bottom_line + multi - 1))
	fi
}

# Replace web config
replace_web_config() {
	conf="$HOMEDIR/$user/conf/web/$domain/$1.conf"
	if [[ "$2" =~ stpl$ ]]; then
		conf="$HOMEDIR/$user/conf/web/$domain/$1.ssl.conf"
	fi

	if [ -e "$conf" ]; then
		sed -i "s|$old|$new|g" $conf
	fi
}

# Delete web configuration
del_web_config() {
	conf="$HOMEDIR/$user/conf/web/$domain/$1.conf"
	local confname="$domain.conf"
	if [[ "$2" =~ stpl$ ]]; then
		conf="$HOMEDIR/$user/conf/web/$domain/$1.ssl.conf"
		confname="$domain.ssl.conf"
	fi

	# Clean up legacy configuration files
	if [ ! -e "$conf" ]; then
		local legacyconf="$HOMEDIR/$user/conf/web/$1.conf"
		if [[ "$2" =~ stpl$ ]]; then
			legacyconf="$HOMEDIR/$user/conf/web/s$1.conf"
		fi
		rm -f $legacyconf

		# Remove old global includes file
		rm -f /etc/$1/conf.d/hestia.conf
	fi

	# Remove domain configuration files and clean up symbolic links
	rm -f "$conf"

	if [ -n "$WEB_SYSTEM" ] && [ "$WEB_SYSTEM" = "$1" ]; then
		rm -f "/etc/$WEB_SYSTEM/conf.d/domains/$confname"
	fi
	if [ -n "$PROXY_SYSTEM" ] && [ "$PROXY_SYSTEM" = "$1" ]; then
		rm -f "/etc/$PROXY_SYSTEM/conf.d/domains/$confname"
	fi
}

# SSL certificate verification
is_web_domain_cert_valid() {
	if [ ! -e "$ssl_dir/$domain.crt" ]; then
		check_result "$E_NOTEXIST" "$ssl_dir/$domain.crt not found"
	fi

	if [ ! -e "$ssl_dir/$domain.key" ]; then
		check_result "$E_NOTEXIST" "$ssl_dir/$domain.key not found"
	fi

	crt_vrf=$(openssl verify $ssl_dir/$domain.crt 2>&1)
	if [ -n "$(echo $crt_vrf | grep 'unable to load')" ]; then
		check_result "$E_INVALID" "SSL Certificate is not valid"
	fi

	if [ -n "$(echo $crt_vrf | grep 'unable to get local issuer')" ]; then
		if [ ! -e "$ssl_dir/$domain.ca" ]; then
			check_result "$E_NOTEXIST" "Certificate Authority not found"
		fi
	fi

	if [ -e "$ssl_dir/$domain.ca" ]; then
		s1=$(openssl x509 -text -in $ssl_dir/$domain.crt 2> /dev/null)
		s1=$(echo "$s1" | grep Issuer | awk -F = '{print $6}' | head -n1)
		s2=$(openssl x509 -text -in $ssl_dir/$domain.ca 2> /dev/null)
		s2=$(echo "$s2" | grep Subject | awk -F = '{print $6}' | head -n1)
		if [ "$s1" != "$s2" ]; then
			check_result "$E_NOTEXIST" "SSL intermediate chain is not valid"
		fi
	fi

	key_vrf=$(grep 'PRIVATE KEY' $ssl_dir/$domain.key | wc -l)
	if [ "$key_vrf" -ne 2 ]; then
		check_result "$E_INVALID" "SSL Key is not valid"
	fi
	if [ -n "$(grep 'ENCRYPTED' $ssl_dir/$domain.key)" ]; then
		check_result "$E_FORBIDEN" "SSL Key is protected (remove pass_phrase)"
	fi

	if pgrep -x "openssl" > /dev/null; then
		pkill openssl
	fi

	openssl s_server -quiet -cert $ssl_dir/$domain.crt \
		-key $ssl_dir/$domain.key >> /dev/null 2>&1 &
	pid=$!
	sleep 0.5
	disown &> /dev/null
	kill $pid &> /dev/null
	check_result $? "ssl certificate key pair is not valid" $E_INVALID
}

#----------------------------------------------------------#
#                        DNS                               #
#----------------------------------------------------------#

# DNS template check
is_dns_template_valid() {
	if [ ! -e "$DNSTPL/$1.tpl" ]; then
		check_result "$E_NOTEXIST" "$1 dns template doesn't exist"
	fi
}

# DNS domain existence check
is_dns_domain_new() {
	dns=$(ls $HESTIA/data/users/*/dns/$1.conf 2> /dev/null)
	if [ -n "$dns" ]; then
		if [ "$2" == 'dns' ]; then
			check_result "$E_EXISTS" "DNS domain $1 exists"
		fi
		dns_user=$(echo "$dns" | cut -f 7 -d /)
		if [ "$dns_user" != "$user" ]; then
			check_result "$E_EXISTS" "DNS domain $1 exists"
		fi
	fi
}

# Update domain zone
update_domain_zone() {
	domain_param=$(grep "DOMAIN='$domain'" $USER_DATA/dns.conf)
	parse_object_kv_list "$domain_param"
	local zone_ttl="$TTL"
	SOA=$(idn2 --quiet "$SOA")
	if [ -z "$SERIAL" ]; then
		SERIAL=$(date +'%Y%m%d01')
	fi
	if [[ "$domain" = *[![:ascii:]]* ]]; then
		domain_idn=$(idn2 --quiet $domain)
	else
		domain_idn=$domain
	fi
	zn_conf="$HOMEDIR/$user/conf/dns/$domain.db"
	echo "\$TTL $TTL
@    IN    SOA    $SOA.    root.$domain_idn. (
                                            $SERIAL
                                            7200
                                            3600
                                            1209600
                                            180 )
" > $zn_conf
	fields='$RECORD\t$TTL\tIN\t$TYPE\t$PRIORITY\t$VALUE'
	while read line; do
		unset TTL
		IFS=$'\n'
		for key in $(echo $line | sed "s/' /'\n/g"); do
			eval ${key%%=*}="${key#*=}"
		done

		# inherit zone TTL if record lacks explicit TTL value
		[ -z "$TTL" ] && TTL="$zone_ttl"

		RECORD=$(idn2 --quiet "$RECORD")
		if [ "$TYPE" = 'CNAME' ] || [ "$TYPE" = 'MX' ]; then
			VALUE=$(idn2 --quiet "$VALUE")
		fi

		if [ "$TYPE" = 'TXT' ]; then
			txtlength=${#VALUE}
			if [ $txtlength -gt 255 ]; then
				already_chunked=0
				if [[ $VALUE == *"\" \""* ]] || [[ $VALUE == *"\"\""* ]]; then
					already_chunked=1
				fi
				if [ $already_chunked -eq 0 ]; then
					if [[ ${VALUE:0:1} = '"' ]]; then
						txtlength=$(($txtlength - 2))
						VALUE=${VALUE:1:txtlength}
					fi
					VALUE=$(echo $VALUE | fold -w 255 | xargs -I '$' echo -n '"$"')
				fi
			fi
		fi

		if [ "$SUSPENDED" != 'yes' ]; then
			eval echo -e "\"$fields\"" | sed "s/%quote%/'/g" >> $zn_conf
		fi
	done < $USER_DATA/dns/$domain.conf
}

# Update zone serial
update_domain_serial() {
	zn_conf="$HOMEDIR/$user/conf/dns/$domain.db"
	if [ -e $zn_conf ]; then
		zn_serial=$(head $zn_conf | grep 'SOA' -A1 | tail -n 1 | sed "s/ //g")
		s_date=$(echo ${zn_serial:0:8})
		c_date=$(date +'%Y%m%d')
		if [ "$s_date" == "$c_date" ]; then
			cur_value=$(echo ${zn_serial:8})
			new_value=$(expr $cur_value + 1)
			len_value=$(expr length $new_value)
			if [ 1 -eq "$len_value" ]; then
				new_value='0'$new_value
			fi
			serial="$c_date""$new_value"
		else
			serial="$(date +'%Y%m%d01')"
		fi
	else
		serial="$(date +'%Y%m%d01')"
	fi
	add_object_key "dns" 'DOMAIN' "$domain" 'SERIAL' 'RECORDS'
	update_object_value 'dns' 'DOMAIN' "$domain" '$SERIAL' "$serial"
}

# Get next DNS record ID
get_next_dnsrecord() {
	if [ -z "$id" ]; then
		curr_str=$(grep "ID=" $USER_DATA/dns/$domain.conf | cut -f 2 -d \' \
			| sort -n | tail -n1)
		id="$((curr_str + 1))"
	fi
}

# Sort DNS records
sort_dns_records() {
	conf="$USER_DATA/dns/$domain.conf"
	cat $conf | sort -n -k 2 -t \' > $conf.tmp
	mv -f $conf.tmp $conf
}

# Check if this is a last record
is_dns_record_critical() {
	str=$(grep "ID='$id'" $USER_DATA/dns/$domain.conf)
	parse_object_kv_list "$str"
	if [ "$TYPE" = 'A' ] || [ "$TYPE" = 'NS' ]; then
		records=$(grep "TYPE='$TYPE'" $USER_DATA/dns/$domain.conf | wc -l)
		if [ $records -le 1 ]; then
			echo "Error: at least one $TYPE record should remain active"
			log_event "$E_INVALID" "$ARGUMENTS"
			exit "$E_INVALID"
		fi
	fi
}

# Check if dns record is valid
is_dns_fqnd() {
	t=$1
	r=$2
	fqdn_type=$(echo $t | grep "^NS\|CNAME\|MX\|PTR\|SRV")
	tree_length=3
	if [[ $t = 'CNAME' || $t = 'MX' || $t = 'PTR' ]]; then
		tree_length=2
	fi
	if [ -n "$fqdn_type" ]; then
		dots=$(echo $dvalue | grep -o "\." | wc -l)
		if [ "$dots" -lt "$tree_length" ]; then
			r=$(echo $r | sed -e "s/\.$//")
			msg="$t record $r should be a fully qualified domain name (FQDN)"
			echo "Error: $msg"
			log_event "$E_INVALID" "$ARGUMENTS"
			exit "$E_INVALID"
		fi
	fi
}

# Validate nameserver
is_dns_nameserver_valid() {
	d=$1
	t=$2
	r=$3
	if [ "$t" = 'NS' ]; then
		remote=$(echo $r | grep ".$domain.$")
		if [ -n "$remote" ]; then
			zone=$USER_DATA/dns/$d.conf
			a_record=${r%.$d.}
			n_record=$(grep "RECORD='$a_record'" $zone | grep "TYPE='A'")
			if [ -z "$n_record" ]; then
				check_result "$E_NOTEXIST" "IN A $a_record.$d does not exist"
			fi
		fi
	fi
}

#----------------------------------------------------------#
#                       MAIL                               #
#----------------------------------------------------------#

# Mail domain existence check
is_mail_domain_new() {
	mail=$(ls $HESTIA/data/users/*/mail/$1.conf 2> /dev/null)
	if [ -n "$mail" ]; then
		if [ "$2" == 'mail' ]; then
			check_result $E_EXISTS "Mail domain $1 exists"
		fi
		mail_user=$(echo "$mail" | cut -f 7 -d /)
		if [ "$mail_user" != "$user" ]; then
			check_result "$E_EXISTS" "Mail domain $1 exists"
		fi
	fi
	mail_sub=$(echo "$1" | cut -f 1 -d .)
	mail_nosub=$(echo "$1" | cut -f 1 -d . --complement)
	for mail_reserved in $(echo "mail $WEBMAIL_ALIAS"); do
		if [ -n "$(ls $HESTIA/data/users/*/mail/$mail_reserved.$1.conf 2> /dev/null)" ]; then
			if [ "$2" == 'mail' ]; then
				check_result "$E_EXISTS" "Required subdomain \"$mail_reserved.$1\" already exists"
			fi
		fi
		if [ -n "$(ls $HESTIA/data/users/*/mail/$mail_nosub.conf 2> /dev/null)" ] && [ "$mail_sub" = "$mail_reserved" ]; then
			if [ "$2" == 'mail' ]; then
				check_result "$E_INVALID" "The subdomain \"$mail_sub.\" is reserved by \"$mail_nosub\""
			fi
		fi
	done
}

# Checking mail account existence
is_mail_new() {
	check_acc=$(grep "ACCOUNT='$1'" $USER_DATA/mail/$domain.conf)
	if [ -n "$check_acc" ]; then
		check_result "$E_EXISTS" "mail account $1 already exists"
	fi
	check_als=$(awk -F "ALIAS='" '{print $2}' $USER_DATA/mail/$domain.conf)
	match=$(echo "$check_als" | cut -f 1 -d "'" | grep $1)
	if [ -n "$match" ]; then
		parse_object_kv_list $(grep "ALIAS='$match'" $USER_DATA/mail/$domain.conf)
		check_als=$(echo ",$ALIAS," | grep ",$1,")
		if [ -n "$check_als" ]; then
			check_result "$E_EXISTS" "mail alias $1 already exists"
		fi
	fi
}

# Add mail server SSL configuration
add_mail_ssl_config() {
	# Ensure that SSL certificate directories exists
	if [ ! -d "$HOMEDIR/$user/conf/mail/$domain/ssl/" ]; then
		mkdir -p $HOMEDIR/$user/conf/mail/$domain/ssl/
	fi

	if [ ! -d "$HESTIA/ssl/mail" ]; then
		mkdir -p $HESTIA/ssl/mail
	fi

	if [ ! -d /etc/dovecot/conf.d/domains ]; then
		mkdir -p /etc/dovecot/conf.d/domains
	fi

	# Add certificate to Hestia user configuration data directory
	if [ -f "$ssl_dir/$domain.crt" ]; then
		cp -f $ssl_dir/$domain.crt $USER_DATA/ssl/mail.$domain.crt
		cp -f $ssl_dir/$domain.key $USER_DATA/ssl/mail.$domain.key
		cp -f $ssl_dir/$domain.crt $USER_DATA/ssl/mail.$domain.pem
		if [ -e "$ssl_dir/$domain.ca" ]; then
			cp -f $ssl_dir/$domain.ca $USER_DATA/ssl/mail.$domain.ca
			echo >> $USER_DATA/ssl/mail.$domain.pem
			cat $USER_DATA/ssl/mail.$domain.ca >> $USER_DATA/ssl/mail.$domain.pem
		fi
	fi

	chmod 660 $USER_DATA/ssl/mail.$domain.*

	# Add certificate to user home directory
	cp -f $USER_DATA/ssl/mail.$domain.crt $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.crt
	cp -f $USER_DATA/ssl/mail.$domain.key $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key
	cp -f $USER_DATA/ssl/mail.$domain.pem $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem
	if [ -e "$USER_DATA/ssl/mail.$domain.ca" ]; then
		cp -f $USER_DATA/ssl/mail.$domain.ca $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.ca
	fi

	# Clean up dovecot configuration (if it exists)
	if [ -f /etc/dovecot/conf.d/domains/$domain.conf ]; then
		rm -f /etc/dovecot/conf.d/domains/$domain.conf
	fi

	# Check if using custom / wildcard mail certificate
	wildcard_domain="\\*.$(echo "$domain" | cut -f 1 -d . --complement)"
	mail_cert_match=$($BIN/v-list-mail-domain-ssl $user $domain | awk '/SUBJECT|ALIASES/' | grep -wE " $domain| $wildcard_domain")

	if [ -n "$mail_cert_match" ]; then
		# Add domain SSL configuration to dovecot
		echo "" >> /etc/dovecot/conf.d/domains/$domain.conf
		echo "local_name $domain {" >> /etc/dovecot/conf.d/domains/$domain.conf
		echo "  ssl_cert = <$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem" >> /etc/dovecot/conf.d/domains/$domain.conf
		echo "  ssl_key = <$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key" >> /etc/dovecot/conf.d/domains/$domain.conf
		echo "}" >> /etc/dovecot/conf.d/domains/$domain.conf

		# Add domain SSL configuration to exim4
		ln -s $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem $HESTIA/ssl/mail/$domain.crt
		ln -s $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key $HESTIA/ssl/mail/$domain.key
	fi

	# Add domain SSL configuration to dovecot
	echo "" >> /etc/dovecot/conf.d/domains/$domain.conf
	echo "local_name mail.$domain {" >> /etc/dovecot/conf.d/domains/$domain.conf
	echo "  ssl_cert = <$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem" >> /etc/dovecot/conf.d/domains/$domain.conf
	echo "  ssl_key = <$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key" >> /etc/dovecot/conf.d/domains/$domain.conf
	echo "}" >> /etc/dovecot/conf.d/domains/$domain.conf

	# Add domain SSL configuration to exim4
	ln -s $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem $HESTIA/ssl/mail/mail.$domain.crt
	ln -s $HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key $HESTIA/ssl/mail/mail.$domain.key

	# Set correct permissions on certificates
	chmod 0750 $HOMEDIR/$user/conf/mail/$domain/ssl
	chown -R $MAIL_USER:mail $HOMEDIR/$user/conf/mail/$domain/ssl
	chmod 0644 $HOMEDIR/$user/conf/mail/$domain/ssl/*
	chown -h $user:mail $HOMEDIR/$user/conf/mail/$domain/ssl/*
	chmod -R 0644 $HESTIA/ssl/mail/*
	chown -h $user:mail $HESTIA/ssl/mail/*
}

# Delete SSL support for mail domain
del_mail_ssl_config() {
	# Check to prevent accidental removal of mismatched certificate
	wildcard_domain="\\*.$(echo "$domain" | cut -f 1 -d . --complement)"
	mail_cert_match=$($BIN/v-list-mail-domain-ssl $user $domain | awk '/SUBJECT|ALIASES/' | grep -wE " $domain| $wildcard_domain")

	# Remove old mail certificates
	rm -f $HOMEDIR/$user/conf/mail/$domain/ssl/*

	# Remove dovecot configuration
	rm -f /etc/dovecot/conf.d/domains/$domain.conf

	# Remove SSL vhost configuration
	rm -f $HOMEDIR/$user/conf/mail/$domain/*.*ssl.conf
	rm -f /etc/$WEB_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
	rm -f /etc/$PROXY_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf

	# Remove SSL certificates
	rm -f $HOMEDIR/$user/conf/mail/$domain/ssl/*
	if [ -n "$mail_cert_match" ]; then
		rm -f $HESTIA/ssl/mail/$domain.crt $HESTIA/ssl/mail/$domain.key
	fi
	rm -f $HESTIA/ssl/mail/mail.$domain.crt $HESTIA/ssl/mail/mail.$domain.key
}

# Delete generated certificates from user configuration data directory
del_mail_ssl_certificates() {
	rm -f $USER_DATA/ssl/mail.$domain.ca
	rm -f $USER_DATA/ssl/mail.$domain.crt
	rm -f $USER_DATA/ssl/mail.$domain.key
	rm -f $USER_DATA/ssl/mail.$domain.pem
	rm -f $HOMEDIR/$user/conf/mail/$domain/ssl/*
}

# Add webmail config
add_webmail_config() {
	mkdir -p "$HOMEDIR/$user/conf/mail/$domain"
	conf="$HOMEDIR/$user/conf/mail/$domain/$1.conf"
	if [[ "$2" =~ stpl$ ]]; then
		conf="$HOMEDIR/$user/conf/mail/$domain/$1.ssl.conf"
	fi

	domain_idn=$domain
	format_domain_idn

	ssl_crt="$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.crt"
	ssl_key="$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.key"
	ssl_pem="$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.pem"
	ssl_ca="$HOMEDIR/$user/conf/mail/$domain/ssl/$domain.ca"

	override_alias=""
	if [ "$WEBMAIL_ALIAS" != "mail" ]; then
		override_alias="mail.$domain"
		override_alias_idn="mail.$domain_idn"
	fi

	# Note: Removing or renaming template variables will lead to broken custom templates.
	#   -If possible custom templates should be automatically upgraded to use the new format
	#   -Alternatively a depreciation period with proper notifications should be considered

	cat $MAILTPL/$1/$2 \
		| sed -e "s|%ip%|$local_ip|g" \
			-e "s|%domain%|$WEBMAIL_ALIAS.$domain|g" \
			-e "s|%domain_idn%|$WEBMAIL_ALIAS.$domain_idn|g" \
			-e "s|%root_domain%|$domain|g" \
			-e "s|%alias%|$override_alias|g" \
			-e "s|%alias_idn%|$override_alias_idn|g" \
			-e "s|%alias_string%|$alias_string|g" \
			-e "s|%email%|info@$domain|g" \
			-e "s|%web_system%|$WEB_SYSTEM|g" \
			-e "s|%web_port%|$WEB_PORT|g" \
			-e "s|%web_ssl_port%|$WEB_SSL_PORT|g" \
			-e "s|%backend_lsnr%|$backend_lsnr|g" \
			-e "s|%rgroups%|$WEB_RGROUPS|g" \
			-e "s|%proxy_system%|$PROXY_SYSTEM|g" \
			-e "s|%proxy_port%|$PROXY_PORT|g" \
			-e "s|%proxy_url%|$PROXY_URL|g" \
			-e "s|%proxy_ssl_port%|$PROXY_SSL_PORT|g" \
			-e "s/%proxy_extensions%/${PROXY_EXT//,/|}/g" \
			-e "s|%user%|$user|g" \
			-e "s|%group%|$user|g" \
			-e "s|%home%|$HOMEDIR|g" \
			-e "s|%docroot%|$docroot|g" \
			-e "s|%sdocroot%|$sdocroot|g" \
			-e "s|%ssl_crt%|$ssl_crt|g" \
			-e "s|%ssl_key%|$ssl_key|g" \
			-e "s|%ssl_pem%|$ssl_pem|g" \
			-e "s|%ssl_ca_str%|$ssl_ca_str|g" \
			-e "s|%ssl_ca%|$ssl_ca|g" \
			> $conf

	process_http2_directive "$conf"

	chown root:$user $conf
	chmod 640 $conf

	if [[ "$2" =~ stpl$ ]]; then
		if [ -n "$WEB_SYSTEM" ]; then
			forcessl="$HOMEDIR/$user/conf/mail/$domain/$WEB_SYSTEM.forcessl.conf"
			rm -f /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
			ln -s $conf /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
		fi
		if [ -n "$PROXY_SYSTEM" ]; then
			forcessl="$HOMEDIR/$user/conf/mail/$domain/$PROXY_SYSTEM.forcessl.conf"
			rm -f /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
			ln -s $conf /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
		fi

		# Add rewrite rules to force HTTPS/SSL connections
		if [ -n "$PROXY_SYSTEM" ] || [ "$WEB_SYSTEM" = 'nginx' ]; then
			echo 'return 301 https://$server_name$request_uri;' > $forcessl
		else
			echo 'RewriteEngine On' > $forcessl
			echo 'RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]' >> $forcessl
		fi

		# Remove old configurations
		find $HOMEDIR/$user/conf/mail/ -maxdepth 1 -type f \( -name "$domain.*" -o -name "ssl.$domain.*" -o -name "*nginx.$domain.*" \) -exec rm {} \;
	else
		if [ -n "$WEB_SYSTEM" ]; then
			rm -f /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
			ln -s $conf /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
		fi
		if [ -n "$PROXY_SYSTEM" ]; then
			rm -f /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
			ln -s $conf /etc/$1/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
		fi
		# Clear old configurations
		find $HOMEDIR/$user/conf/mail/ -maxdepth 1 -type f \( -name "$domain.*" \) -exec rm {} \;
	fi
}

# Delete webmail support
del_webmail_config() {
	if [ -n "$WEB_SYSTEM" ]; then
		rm -f $HOMEDIR/$user/conf/mail/$domain/$WEB_SYSTEM.conf
		rm -f /etc/$WEB_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
	fi

	if [ -n "$PROXY_SYSTEM" ]; then
		rm -f $HOMEDIR/$user/conf/mail/$domain/$PROXY_SYSTEM.*conf
		rm -f /etc/$PROXY_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.conf
	fi
}

# Delete SSL webmail support
del_webmail_ssl_config() {
	if [ -n "$WEB_SYSTEM" ]; then
		rm -f $HOMEDIR/$user/conf/mail/$domain/$WEB_SYSTEM.*ssl.conf
		rm -f /etc/$WEB_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
	fi

	if [ -n "$PROXY_SYSTEM" ]; then
		rm -f $HOMEDIR/$user/conf/mail/$domain/$PROXY_SYSTEM.*ssl.conf
		rm -f /etc/$PROXY_SYSTEM/conf.d/domains/$WEBMAIL_ALIAS.$domain.ssl.conf
	fi
}

#----------------------------------------------------------#
#                        CMN                               #
#----------------------------------------------------------#

# Checking domain existence
is_domain_new() {
	type=$1
	for object in ${2//,/ }; do
		if [ -n "$WEB_SYSTEM" ]; then
			is_web_domain_new $object $type
			is_web_alias_new $object $type
		fi
		if [ -n "$DNS_SYSTEM" ]; then
			is_dns_domain_new $object $type
		fi
		if [ -n "$MAIL_SYSTEM" ]; then
			is_mail_domain_new $object $type
		fi
	done
}

# Get domain variables
get_domain_values() {
	parse_object_kv_list $(grep "DOMAIN='$domain'" $USER_DATA/$1.conf)
}

#----------------------------------------------------------#
# 2 Char domain name detection                             #
#----------------------------------------------------------#

is_valid_extension() {
	if [ ! -e "$HESTIA/data/extensions/public_suffix_list.dat" ]; then
		mkdir $HESTIA/data/extensions/
		chmod 750 $HESTIA/data/extensions/
		/usr/bin/wget --tries=3 --timeout=15 --read-timeout=15 --waitretry=3 --no-dns-cache --quiet -O $HESTIA/data/extensions/public_suffix_list.dat https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat
	fi
	test_domain=$(idn2 -d "$1")
	extension=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 1 | /usr/bin/rev)
	exten=$(grep "^$extension\$" $HESTIA/data/extensions/public_suffix_list.dat)
}

is_valid_2_part_extension() {
	if [ ! -e "$HESTIA/data/extensions/public_suffix_list.dat" ]; then
		mkdir $HESTIA/data/extensions/
		chmod 750 $HESTIA/data/extensions/
		/usr/bin/wget --tries=3 --timeout=15 --read-timeout=15 --waitretry=3 --no-dns-cache --quiet -O $HESTIA/data/extensions/public_suffix_list.dat https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat
	fi
	test_domain=$(idn2 -d "$1")
	extension=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 1-2 | /usr/bin/rev)
	exten=$(grep "^$extension\$" $HESTIA/data/extensions/public_suffix_list.dat)
}

get_base_domain() {
	test_domain=$1
	is_valid_extension "$test_domain"
	if [ $? -ne 0 ]; then
		basedomain=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 1-2 | /usr/bin/rev)
	else
		is_valid_2_part_extension "$test_domain"
		if [ $? -ne 0 ]; then
			basedomain=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 1-2 | /usr/bin/rev)
		else
			extension=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 1-2 | /usr/bin/rev)
			partdomain=$(/bin/echo "${test_domain}" | /usr/bin/rev | /usr/bin/cut -d "." --output-delimiter="." -f 3 | /usr/bin/rev)
			basedomain="$partdomain.$extension"
		fi
	fi
}

is_base_domain_owner() {
	for object in ${1//,/ }; do
		if [ "$object" != "none" ]; then
			get_base_domain $object
			web=$(grep -F -H -h "DOMAIN='$basedomain'" $HESTIA/data/users/*/web.conf)
			if [ "$ENFORCE_SUBDOMAIN_OWNERSHIP" = "yes" ]; then
				if [ -n "$web" ]; then
					parse_object_kv_list "$web"
					if [ -z "$ALLOW_USERS" ] || [ "$ALLOW_USERS" != "yes" ]; then
						# Don't care if $basedomain all ready exists only if the owner is of the base domain is the current user
						check=$(is_domain_new "" $basedomain)
						if [ $? -ne 0 ]; then
							echo "Error: Unable to add $object. $basedomain belongs to a different user"
							exit 4
						fi
					fi
				else
					check=$(is_domain_new "" "$basedomain")
					if [ $? -ne 0 ]; then
						echo "Error: Unable to add $object. $basedomain belongs to a different user"
						exit 4
					fi
				fi
			fi
		fi
	done
}

#----------------------------------------------------------#
#           Process "http2" directive for NGINX            #
#----------------------------------------------------------#

process_http2_directive() {
	if [ -e /etc/nginx/conf.d/http2-directive.conf ]; then
		while IFS= read -r old_param; do
			new_param="$(echo "$old_param" | sed 's/\shttp2//')"
			sed -i "s/$old_param/$new_param/" "$1"
		done < <(grep -E "listen.*(\bssl\b(\s|.+){1,}\bhttp2\b|\bhttp2\b(\s|.+){1,}\bssl\b).*;" "$1")
	else
		if version_ge "$(nginx -v 2>&1 | cut -d'/' -f2)" "1.25.1"; then
			echo "http2 on;" > /etc/nginx/conf.d/http2-directive.conf

			while IFS= read -r old_param; do
				new_param="$(echo "$old_param" | sed 's/\shttp2//')"
				sed -i "s/$old_param/$new_param/" "$1"
			done < <(grep -E "listen.*(\bssl\b(\s|.+){1,}\bhttp2\b|\bhttp2\b(\s|.+){1,}\bssl\b).*;" "$1")
		else
			listen_ssl="$(grep -E "listen.*\s\bssl\b(?:\s)*.*;" "$1")"
			listen_http2="$(grep -E "listen.*(\bssl\b(\s|.+){1,}\bhttp2\b|\bhttp2\b(\s|.+){1,}\bssl\b).*;" "$1")"

			if [ -n "$listen_ssl" ] && [ -z "$listen_http2" ]; then
				while IFS= read -r old_param; do
					new_param="$(echo "$old_param" | sed 's/\sssl/ ssl http2/')"
					sed -i "s/$old_param/$new_param/" "$1"
				done < <(grep -E "listen.*\s\bssl\b(?:\s)*.*;" "$1")
			fi
		fi
	fi
}
