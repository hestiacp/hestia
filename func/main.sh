#!/usr/bin/env bash

#===========================================================================#
#                                                                           #
# Hestia Control Panel - Core Function Library                              #
#                                                                           #
#===========================================================================#

# Source conf function for correct variable initialisation
source_conf() {
	while IFS='= ' read -r lhs rhs; do
		if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
			rhs="${rhs%%^\#*}" # Del in line right comments
			rhs="${rhs%%*( )}" # Del trailing spaces
			rhs="${rhs%\'*}"   # Del opening string quotes
			rhs="${rhs#\'*}"   # Del closing string quotes
			declare -g $lhs="$rhs"
		fi
	done < $1
}

if [ -z "$user" ]; then
	if [ -z "$ROOT_USER" ]; then
		if [ -z "$HESTIA" ]; then
			# shellcheck source=/etc/hestiacp/hestia.conf
			source /etc/hestiacp/hestia.conf
		fi
		source_conf "$HESTIA/conf/hestia.conf" # load config file
	fi
	user="$ROOT_USER"
fi

# Internal variables
HOMEDIR='/home'
BACKUP='/backup'
BACKUP_GZIP=9
BACKUP_DISK_LIMIT=95
BACKUP_LA_LIMIT=$(grep -c '^processor' /proc/cpuinfo)
RRD_STEP=300
BIN=$HESTIA/bin
HESTIA_INSTALL_DIR="$HESTIA/install/deb"
HESTIA_COMMON_DIR="$HESTIA/install/common"
HESTIA_BACKUP="/root/hst_backups/$(date +%d%m%Y%H%M)"
HESTIA_PHP="$HESTIA/php/bin/php"
USER_DATA=$HESTIA/data/users/$user
WEBTPL=$HESTIA/data/templates/web
MAILTPL=$HESTIA/data/templates/mail
DNSTPL=$HESTIA/data/templates/dns
RRD=$HESTIA/web/rrd
SENDMAIL="$HESTIA/web/inc/mail-wrapper.php"
HESTIA_GIT_REPO="https://raw.githubusercontent.com/hestiacp/hestiacp"
HESTIA_THEMES="$HESTIA/web/css/themes"
HESTIA_THEMES_CUSTOM="$HESTIA/web/css/themes/custom"
SCRIPT="$(basename $0)"
CHECK_RESULT_CALLBACK=""

# Return codes
OK=0
E_ARGS=1
E_INVALID=2
E_NOTEXIST=3
E_EXISTS=4
E_SUSPENDED=5
E_UNSUSPENDED=6
E_INUSE=7
E_LIMIT=8
E_PASSWORD=9
E_FORBIDEN=10
E_DISABLED=11
E_PARSING=12
E_DISK=13
E_LA=14
E_CONNECT=15
E_FTP=16
E_DB=17
E_RRD=18
E_UPDATE=19
E_RESTART=20

# Detect operating system
detect_os() {
	if [ -e "/etc/os-release" ]; then
		get_os_type=$(grep "^ID=" /etc/os-release | cut -f 2 -d '=')
		if [ "$get_os_type" = "ubuntu" ]; then
			if [ -e '/usr/bin/lsb_release' ]; then
				OS_VERSION="$(lsb_release -s -r)"
				OS_TYPE='Ubuntu'
			fi
		elif [ "$get_os_type" = "debian" ]; then
			OS_TYPE='Debian'
			OS_VERSION=$(cat /etc/debian_version | grep -o "[0-9]\{1,2\}" | head -n1)
		fi
	else
		OS_TYPE="Unsupported OS"
		OS_VERSION="Unknown"
	fi
}

# Generate time stamp
new_timestamp() {
	time_n_date=$(date +'%T %F')
	time=$(echo "$time_n_date" | cut -f 1 -d \ )
	date=$(echo "$time_n_date" | cut -f 2 -d \ )
}

# Event string for logger
ARGS=("$@")
for ((I = 1; I <= $#; I++)); do
	if [[ "$HIDE" != "$I" ]]; then
		ARGUMENTS="$ARGUMENTS '${ARGS[${I} - 1]}'"
	else
		ARGUMENTS="$ARGUMENTS '******'"
	fi
done

# Log event function
log_event() {
	if [ -z "$time" ]; then
		LOG_TIME="$(date +'%F %T') $(basename $0)"
	else
		LOG_TIME="$date $time $(basename $0)"
	fi
	if [ "$1" -eq 0 ]; then
		echo "$LOG_TIME $2" >> $HESTIA/log/system.log
	else
		echo "$LOG_TIME $2 [Error $1]" >> $HESTIA/log/error.log
	fi
}

# Log user history
log_history() {
	message=${1//\'/\´} # Avoid single quotes broken the log
	evt_level=${2:-$event_level}
	log_user=${3-$user}
	evt_category=${4:-$event_category}

	# Set default event level and category if not specified
	if [ -z "$evt_level" ]; then
		evt_level="Info"
	fi
	if [ -z "$evt_category" ]; then
		evt_category="System"
	fi

	# Log system events to system log file
	if [ "$log_user" = "system" ]; then
		log=$HESTIA/log/activity.log
	else
		if ! $BIN/v-list-user "$log_user" > /dev/null; then
			return $E_NOTEXIST
		fi
		log=$HESTIA/data/users/$log_user/history.log
	fi
	touch $log

	if [ '300' -lt "$(wc -l $log | cut -f 1 -d ' ')" ]; then
		tail -n 250 $log > $log.moved
		mv -f $log.moved $log
		chmod 660 $log
	fi

	if [ -z "$date" ]; then
		time_n_date=$(date +'%T %F')
		time=$(echo "$time_n_date" | cut -f 1 -d \ )
		date=$(echo "$time_n_date" | cut -f 2 -d \ )
	fi

	curr_str=$(tail -n1 $log | grep "ID=" --text | cut -f2 -d \')
	id="$((curr_str + 1))"
	echo "ID='$id' DATE='$date' TIME='$time' LEVEL='$evt_level' CATEGORY='$evt_category' MESSAGE='$message'" >> $log
}

# Result checker
check_result() {
	if [ $1 -ne 0 ]; then
		local err_code="${3:-$1}"
		if [[ -n "$CHECK_RESULT_CALLBACK" && "$(type -t "$CHECK_RESULT_CALLBACK")" == 'function' ]]; then
			$CHECK_RESULT_CALLBACK "$err_code" "$2"
		else
			echo "Error: $2"
			log_event "$err_code" "$ARGUMENTS"
		fi

		exit $err_code
	fi
}

# Argument list checker
check_args() {
	if [ "$1" -gt "$2" ]; then
		echo "Usage: $(basename $0) $3"
		check_result "$E_ARGS" "not enought arguments" > /dev/null
	fi
}

# Define version check function
version_ge() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" -o -n "$1" -a "$1" = "$2"; }

# Subsystem checker
is_system_enabled() {
	if [ -z "$1" ] || [ "$1" = no ]; then
		check_result "$E_DISABLED" "$2 is not enabled"
	fi
}

# User package check
is_package_full() {
	case "$1" in
		WEB_DOMAINS) used=$(wc -l $USER_DATA/web.conf) ;;
		WEB_ALIASES) used=$(echo $aliases | tr ',' '\n' | wc -l) ;;
		DNS_DOMAINS) used=$(wc -l $USER_DATA/dns.conf) ;;
		DNS_RECORDS) used=$(wc -l $USER_DATA/dns/$domain.conf) ;;
		MAIL_DOMAINS) used=$(wc -l $USER_DATA/mail.conf) ;;
		MAIL_ACCOUNTS) used=$(wc -l $USER_DATA/mail/$domain.conf) ;;
		DATABASES) used=$(wc -l $USER_DATA/db.conf) ;;
		CRON_JOBS) used=$(wc -l $USER_DATA/cron.conf) ;;
	esac
	used=$(echo "$used" | cut -f 1 -d \ )
	limit=$(grep "^$1=" $USER_DATA/user.conf | cut -f 2 -d \')
	if [ "$1" = WEB_ALIASES ]; then
		# Used is always calculated with the new alias added
		if [ "$limit" != 'unlimited' ] && [[ "$used" -gt "$limit" ]]; then
			check_result "$E_LIMIT" "$1 limit is reached :: upgrade user package"
		fi
	else
		if [ "$limit" != 'unlimited' ] && [[ "$used" -ge "$limit" ]]; then
			check_result "$E_LIMIT" "$1 limit is reached :: upgrade user package"
		fi
	fi
}

# User owner for reseller plugin
get_user_owner() {
	if [ -z "$RESELLER_KEY" ]; then
		owner="$ROOT_USER"
	else
		owner=$(grep "^OWNER" $USER_DATA/user.conf | cut -f 2 -d \')
		if [ -z "$owner" ]; then
			owner="$ROOT_USER"
		fi
	fi
}

# Random password generator
generate_password() {
	matrix=$1
	length=$2
	if [ -z "$matrix" ]; then
		matrix="A-Za-z0-9"
	fi
	if [ -z "$length" ]; then
		length=16
	fi
	head /dev/urandom | tr -dc $matrix | head -c$length
}

# Package existence check
is_package_valid() {
	if [ -z $1 ]; then
		if [ ! -e "$HESTIA/data/packages/$package.pkg" ]; then
			check_result "$E_NOTEXIST" "package $package doesn't exist"
		fi
	else
		if [ ! -e "$HESTIA/data/packages/$1.pkg" ]; then
			check_result "$E_NOTEXIST" "package $1 doesn't exist"
		fi
	fi

}

is_package_new() {
	if [ -e "$HESTIA/data/packages/$1.pkg" ]; then
		echo "Error: package $1 already exists."
		log_event "$E_EXISTS" "$ARGUMENTS"
		exit "$E_EXISTS"
	fi
}

# Validate system type
is_type_valid() {
	if [ -z "$(echo $1 | grep -w $2)" ]; then
		check_result "$E_INVALID" "$2 type is invalid"
	fi
}

# Check user backup settings
is_backup_enabled() {
	BACKUPS=$(grep "^BACKUPS=" $USER_DATA/user.conf | cut -f2 -d \')
	if [ -z "$BACKUPS" ] || [[ "$BACKUPS" -le '0' ]]; then
		check_result "$E_DISABLED" "user backup is disabled"
	fi
}

is_incremental_backup_enabled() {
	BACKUPS_INCREMENTAL=$(grep "^BACKUPS_INCREMENTAL=" $USER_DATA/user.conf | cut -f2 -d \')
	if [ -z "$BACKUPS_INCREMENTAL" ] || [[ "$BACKUPS_INCREMENTAL" != "yes" ]]; then
		check_result "$E_DISABLED" "incremental backups are disabled"
	fi
}

# Check user backup settings
is_backup_scheduled() {
	if [ -e "$HESTIA/data/queue/backup.pipe" ]; then
		check_q=$(grep " $user " $HESTIA/data/queue/backup.pipe | grep $1)
		if [ -n "$check_q" ]; then
			check_result "$E_EXISTS" "$1 is already scheduled"
		fi
	fi
}

# Check if object is new
is_object_new() {
	if [ $2 = 'USER' ]; then
		if [ -d "$USER_DATA" ]; then
			object="OK"
		fi
	else
		object=$(grep "$2='$3'" $USER_DATA/$1.conf)
	fi
	if [ -n "$object" ]; then
		check_result "$E_EXISTS" "$2=$3 already exists"
	fi
}

# Check if object is valid
is_object_valid() {
	if [ $2 = 'USER' ]; then
		tstpath="$(readlink -f "$HESTIA/data/users/$3")"
		if [ "$(dirname "$tstpath")" != "$(readlink -f "$HESTIA/data/users")" ] || [ ! -d "$HESTIA/data/users/$3" ]; then
			check_result "$E_NOTEXIST" "$1 $3 doesn't exist"
		fi
	elif [ $2 = 'KEY' ]; then
		local key="$(basename "$3")"

		if [[ -z "$key" || ${#key} -lt 16 ]] || [[ ! -f "$HESTIA/data/access-keys/${key}" && ! -f "$HESTIA/data/access-keys/$key" ]]; then
			check_result "$E_NOTEXIST" "$1 $3 doesn't exist"
		fi
	else
		object=$(grep "$2='$3'" $HESTIA/data/users/$user/$1.conf)
		if [ -z "$object" ]; then
			arg1=$(basename $1)
			arg2=$(echo $2 | tr '[:upper:]' '[:lower:]')
			check_result "$E_NOTEXIST" "$arg1 $arg2 $3 doesn't exist"
		fi
	fi
}

# Check if a object string with key values pairs has the correct format and load it afterwards
parse_object_kv_list_non_eval() {
	local str
	local objkv obj_key obj_val
	local OLD_IFS="$IFS"

	str=${@//$'\n'/ }
	str=${str//\"/\\\"}
	str=${str//$/\\$}
	IFS=$'\n'

	# Extract and loop trough each key-value pair. (Regex test: https://regex101.com/r/eiMufk/5)
	for objkv in $(echo "$str" | perl -n -e "while(/\b([a-zA-Z]+[\w]*)='(.*?)'(\s|\$)/g) {print \$1.'='.\$2 . \"\n\" }"); do

		if ! [[ "$objkv" =~ ^([[:alnum:]][_[:alnum:]]{0,64}[[:alnum:]])=(\'?[^\']+?\'?)?$ ]]; then
			check_result "$E_INVALID" "Invalid key value format [$objkv]"
		fi

		obj_key=${objkv%%=*} # strip everything after first  '=' char
		obj_val=${objkv#*=}  # strip everything before first '=' char
		declare -g $obj_key="$obj_val"

	done
	IFS="$OLD_IFS"
}

# Check if a object string with key values pairs has the correct format and load it afterwards
parse_object_kv_list() {
	local str
	local objkv
	local suboutput
	local OLD_IFS="$IFS"

	str=${@//$'\n'/ }
	str=${str//\"/\\\"}
	str=${str//$/\\$}
	IFS=$'\n'

	suboutput=$(setpriv --clear-groups --reuid nobody --regid nogroup bash -c "PS4=''; set -xe; eval \"${str}\"" 2>&1)
	check_result $? "Invalid object format: ${str}" $E_INVALID

	for objkv in $suboutput; do

		if [[ "$objkv" =~ ^'eval ' ]]; then
			continue
		fi

		if ! [[ "$objkv" =~ ^([[:alnum:]][_[:alnum:]]{0,64}[[:alnum:]])=(\'?[^\']+?\'?)?$ ]]; then
			check_result "$E_INVALID" "Invalid key value format [$objkv]"
		fi

		eval "$objkv"
	done
	IFS="$OLD_IFS"
}

# Check if object is supended
is_object_suspended() {
	if [ $2 = 'USER' ]; then
		spnd=$(cat $USER_DATA/$1.conf | grep "SUSPENDED='yes'")
	else
		spnd=$(grep "$2='$3'" $USER_DATA/$1.conf | grep "SUSPENDED='yes'")
	fi
	if [ -z "$spnd" ]; then
		check_result "$E_UNSUSPENDED" "$(basename $1) $3 is not suspended"
	fi
}

# Check if object is unsupended
is_object_unsuspended() {
	if [ $2 = 'USER' ]; then
		spnd=$(cat $USER_DATA/$1.conf | grep "SUSPENDED='yes'")
	else
		spnd=$(grep "$2='$3'" $USER_DATA/$1.conf | grep "SUSPENDED='yes'")
	fi
	if [ -n "$spnd" ]; then
		check_result "$E_SUSPENDED" "$(basename $1) $3 is suspended"
	fi
}

# Check if object value is empty
is_object_value_empty() {
	str=$(grep "$2='$3'" $USER_DATA/$1.conf)
	parse_object_kv_list "$str"
	eval value=$4
	if [ -n "$value" ] && [ "$value" != 'no' ]; then
		check_result "$E_EXISTS" "${4//$/}=$value already exists"
	fi
}

# Check if object value is empty
is_object_value_exist() {
	str=$(grep "$2='$3'" $USER_DATA/$1.conf)
	parse_object_kv_list "$str"
	eval value=$4
	if [ -z "$value" ] || [ "$value" = 'no' ]; then
		check_result "$E_NOTEXIST" "${4//$/}=$value doesn't exist"
	fi
}

# Check if password is transmitted via file
is_password_valid() {
	if [[ "$password" =~ ^/tmp/ ]]; then
		if ! [[ "$password" == *../* ]]; then
			if [ -f "$password" ]; then
				password="$(head -n1 $password)"
			fi
		fi
	fi
}

# Check if hash is transmitted via file
is_hash_valid() {
	if [[ "$hash" =~ ^/tmp/ ]]; then
		if ! [[ "$hash" == *../* ]]; then
			if [ -f "$hash" ]; then
				hash="$(head -n1 $hash)"
			fi
		fi
	fi
}

# Check if directory is a symlink
is_dir_symlink() {
	if [[ -L "$1" ]]; then
		check_result "$E_FORBIDEN" "$1 directory is a symlink"
	fi
}

# Get object value
get_object_value() {
	object=$(grep "$2='$3'" $USER_DATA/$1.conf)
	parse_object_kv_list "$object"
	eval echo $4
}

get_object_values() {
	parse_object_kv_list $(grep "$2='$3'" $USER_DATA/$1.conf)
}

# Update object value
update_object_value() {
	row=$(grep -nF "$2='$3'" $USER_DATA/$1.conf)
	lnr=$(echo $row | cut -f 1 -d ':')
	object=$(echo $row | sed "s/^$lnr://")
	parse_object_kv_list "$object"
	eval old="$4"
	old=$(echo "$old" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/\//\\\//g')
	new=$(echo "$5" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/\//\\\//g')
	sed -i "$lnr s/${4//$/}='${old//\*/\\*}'/${4//$/}='${new//\*/\\*}'/g" \
		$USER_DATA/$1.conf
}

# Add object key
add_object_key() {
	row=$(grep -n "$2='$3'" $USER_DATA/$1.conf)
	lnr=$(echo $row | cut -f 1 -d ':')
	object=$(echo $row | sed "s/^$lnr://")
	if [ -z "$(echo $object | grep $4=)" ]; then
		eval old="$4"
		sed -i "$lnr s/$5='/$4='' $5='/" $USER_DATA/$1.conf
	fi
}

# Search objects
search_objects() {
	OLD_IFS="$IFS"
	IFS=$'\n'
	if [ -f $USER_DATA/$1.conf ]; then
		for line in $(grep $2=\'$3\' $USER_DATA/$1.conf); do
			parse_object_kv_list "$line"
			eval echo \$$4
		done
	fi
	IFS="$OLD_IFS"
}

# Get user value
get_user_value() {
	grep "^${1//$/}=" $USER_DATA/user.conf | head -1 | awk -F "'" '{print $2}'
}

# Update user value in user.conf
update_user_value() {
	key="${2//$/}"
	lnr=$(grep -n "^$key='" $HESTIA/data/users/$1/user.conf | cut -f 1 -d ':')
	if [ -n "$lnr" ]; then
		sed -i "$lnr d" $HESTIA/data/users/$1/user.conf
		sed -i "$lnr i\\$key='${3}'" $HESTIA/data/users/$1/user.conf
	fi
}

# Increase user counter
increase_user_value() {
	key="${2//$/}"
	factor="${3-1}"
	conf="$HESTIA/data/users/$1/user.conf"
	old=$(grep "$key=" $conf | cut -f 2 -d \')
	if [ -z "$old" ]; then
		old=0
	fi
	new=$((old + factor))
	sed -i "s/$key='$old'/$key='$new'/g" $conf
}

# Decrease user counter
decrease_user_value() {
	key="${2//$/}"
	factor="${3-1}"
	conf="$HESTIA/data/users/$1/user.conf"
	old=$(grep "$key=" $conf | cut -f 2 -d \')
	if [ -z "$old" ]; then
		old=0
	fi
	if [ "$old" -le 1 ]; then
		new=0
	else
		new=$((old - factor))
	fi
	if [ "$new" -lt 0 ]; then
		new=0
	fi
	sed -i "s/$key='$old'/$key='$new'/g" $conf
}

# Notify user
send_notice() {
	topic=$1
	notice=$2

	if [ "$notify" = 'yes' ]; then
		touch $USER_DATA/notifications.conf
		chmod 660 $USER_DATA/notifications.conf

		time_n_date=$(date +'%T %F')
		time=$(echo "$time_n_date" | cut -f 1 -d \ )
		date=$(echo "$time_n_date" | cut -f 2 -d \ )

		nid=$(grep "NID=" $USER_DATA/notifications.conf | cut -f 2 -d \')
		nid=$(echo "$nid" | sort -n | tail -n1)
		if [ -n "$nid" ]; then
			nid="$((nid + 1))"
		else
			nid=1
		fi

		str="NID='$nid' TOPIC='$topic' NOTICE='$notice' TYPE='$type'"
		str="$str ACK='no' TIME='$time' DATE='$date'"

		echo "$str" >> $USER_DATA/notifications.conf

		if [ -z "$(grep NOTIFICATIONS $USER_DATA/user.conf)" ]; then
			sed -i "s/^TIME/NOTIFICATIONS='yes'\nTIME/g" $USER_DATA/user.conf
		else
			update_user_value "$user" '$NOTIFICATIONS' "yes"
		fi
	fi
}

# Recalculate U_DISK value
recalc_user_disk_usage() {
	u_usage=0
	if [ -f "$USER_DATA/web.conf" ]; then
		usage=0
		dusage=$(grep 'U_DISK=' $USER_DATA/web.conf \
			| awk -F "U_DISK='" '{print $2}' | cut -f 1 -d \')
		for disk_usage in $dusage; do
			usage=$((usage + disk_usage))
		done
		d=$(grep "U_DISK_WEB='" $USER_DATA/user.conf | cut -f 2 -d \')
		sed -i "s/U_DISK_WEB='$d'/U_DISK_WEB='$usage'/g" $USER_DATA/user.conf
		u_usage=$((u_usage + usage))
	fi

	if [ -f "$USER_DATA/mail.conf" ]; then
		usage=0
		dusage=$(grep 'U_DISK=' $USER_DATA/mail.conf \
			| awk -F "U_DISK='" '{print $2}' | cut -f 1 -d \')
		for disk_usage in $dusage; do
			usage=$((usage + disk_usage))
		done
		d=$(grep "U_DISK_MAIL='" $USER_DATA/user.conf | cut -f 2 -d \')
		sed -i "s/U_DISK_MAIL='$d'/U_DISK_MAIL='$usage'/g" $USER_DATA/user.conf
		u_usage=$((u_usage + usage))
	fi

	if [ -f "$USER_DATA/db.conf" ]; then
		usage=0
		dusage=$(grep 'U_DISK=' $USER_DATA/db.conf \
			| awk -F "U_DISK='" '{print $2}' | cut -f 1 -d \')
		for disk_usage in $dusage; do
			usage=$((usage + disk_usage))
		done
		d=$(grep "U_DISK_DB='" $USER_DATA/user.conf | cut -f 2 -d \')
		sed -i "s/U_DISK_DB='$d'/U_DISK_DB='$usage'/g" $USER_DATA/user.conf
		u_usage=$((u_usage + usage))
	fi
	usage=$(grep 'U_DISK_DIRS=' $USER_DATA/user.conf | cut -f 2 -d "'")
	u_usage=$((u_usage + usage))
	old=$(grep "U_DISK='" $USER_DATA/user.conf | cut -f 2 -d \')
	sed -i "s/U_DISK='$old'/U_DISK='$u_usage'/g" $USER_DATA/user.conf
}

# Recalculate U_BANDWIDTH value
recalc_user_bandwidth_usage() {
	usage=0
	bandwidth_usage=$(grep 'U_BANDWIDTH=' $USER_DATA/web.conf \
		| awk -F "U_BANDWIDTH='" '{print $2}' | cut -f 1 -d \')
	for bandwidth in $bandwidth_usage; do
		usage=$((usage + bandwidth))
	done
	old=$(grep "U_BANDWIDTH='" $USER_DATA/user.conf | cut -f 2 -d \')
	sed -i "s/U_BANDWIDTH='$old'/U_BANDWIDTH='$usage'/g" $USER_DATA/user.conf
}

# Get next cron job id
get_next_cronjob() {
	if [ -z "$job" ]; then
		curr_str=$(grep "JOB=" $USER_DATA/cron.conf | cut -f 2 -d \' \
			| sort -n | tail -n1)
		job="$((curr_str + 1))"
	fi
}

# Sort cron jobs by id
sort_cron_jobs() {
	cat $USER_DATA/cron.conf | sort -n -k 2 -t \' > $USER_DATA/cron.tmp
	mv -f $USER_DATA/cron.tmp $USER_DATA/cron.conf
}

# Sync cronjobs with system cron
sync_cron_jobs() {
	source_conf "$USER_DATA/user.conf"
	if [ -e "/var/spool/cron/crontabs" ]; then
		crontab="/var/spool/cron/crontabs/$user"
	else
		crontab="/var/spool/cron/$user"
	fi

	# remove file if exists
	if [ -e "$crontab" ]; then
		rm -f $crontab
	fi

	# touch new crontab file
	touch $crontab

	if [ "$CRON_REPORTS" = 'yes' ]; then
		echo "MAILTO=$CONTACT" > $crontab
		echo 'CONTENT_TYPE="text/plain; charset=utf-8"' >> $crontab
	else
		echo 'MAILTO=""' > $crontab
	fi

	while read line; do
		parse_object_kv_list "$line"
		if [ "$SUSPENDED" = 'no' ]; then
			echo "$MIN $HOUR $DAY $MONTH $WDAY $CMD" \
				| sed -e "s/%quote%/'/g" -e "s/%dots%/:/g" \
					>> $crontab
		fi
	done < $USER_DATA/cron.conf
	chown $user:$user $crontab
	chmod 600 $crontab
}

# Validates Local part email and mail alias
is_localpart_format_valid() {
	if [ ${#1} -eq 1 ]; then
		if ! [[ "$1" =~ ^[[:alnum:]]$ ]]; then
			check_result "$E_INVALID" "invalid $2 format :: $1"
		fi
	else
		if [ -n "$3" ]; then
			maxlenght=$(($3 - 2))
			# Allow leading and trailing special characters by adjusting the regex
			if ! [[ "$1" =~ ^[[:alnum:]_.-][[:alnum:]_.-]{0,$maxlenght}[[:alnum:]_.-]$ ]]; then
				check_result "$E_INVALID" "invalid $2 format :: $1"
			fi
		else
			# Allow leading and trailing special characters by adjusting the regex
			if ! [[ "$1" =~ ^[[:alnum:]_.-][[:alnum:]_.-]{0,28}[[:alnum:]_.-]$ ]]; then
				check_result "$E_INVALID" "invalid $2 format :: $1"
			fi
		fi
	fi
	if [ "$1" != "${1//[^[:ascii:]]/}" ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Username / ftp username format validator
is_user_format_valid() {
	if [ ${#1} -eq 1 ]; then
		if ! [[ "$1" =~ ^^[[:alnum:]]$ ]]; then
			check_result "$E_INVALID" "invalid $2 format :: $1"
		fi
	else
		if [ -n "$3" ]; then
			maxlenght=$(($3 - 2))
			if ! [[ "$1" =~ ^[[:alnum:]][-|\.|_[:alnum:]]{0,$maxlenght}[[:alnum:]]$ ]]; then
				check_result "$E_INVALID" "invalid $2 format :: $1"
			fi
		else
			if ! [[ "$1" =~ ^[[:alnum:]][-|\.|_[:alnum:]]{0,28}[[:alnum:]]$ ]]; then
				check_result "$E_INVALID" "invalid $2 format :: $1"
			fi
		fi
	fi
	if [ "$1" != "${1//[^[:ascii:]]/}" ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi

	# Only for new users
	if [[ "$FROM_V_ADD_USER" == "true" ]]; then
		if ! [[ "$1" =~ ^[a-zA-Z][-|_[:alnum:]]{0,28}[[:alnum:]]$ ]]; then
			check_result "$E_INVALID" "invalid $2 format :: $1"
		fi
	fi
}

# Proxy format validator
is_proxy_url_valid() {
	local url=$1
	echo $url

	if [[ -z "$url" ]]; then
		return 0
	fi

	local url_regex='^(https?://|http://)[a-zA-Z0-9.-]+(:[0-9]{1,5})?$'

	if [[ ! $url =~ $url_regex ]]; then
		check_result "$E_INVALID" "Invalid proxy URL format" $object_name
	fi

	if [[ $url == *".."* ]] || [[ $url == *"\\"* ]] || [[ $url == *"%"* ]]; then
		check_result "$E_INVALID" "Proxy URL contains unsafe characters" $object_name
	fi

	local test=$(echo "$url" | head -n1)
	if [[ "$test" != "$url" ]]; then
		check_result "$E_INVALID" "Proxy URL contains newline characters" $object_name
	fi
}

# Domain format validator
is_domain_format_valid() {
	object_name=${2-domain}
	exclude="[!|@|#|$|^|&|*|(|)|+|=|{|}|:|,|<|>|?|_|/|\|\"|'|;|%|\`| ]"
	if [[ $1 =~ $exclude ]] || [[ $1 =~ ^[0-9]+$ ]] || [[ $1 =~ \.\. ]] || [[ $1 =~ $(printf '\t') ]] || [[ "$1" = "www" ]]; then
		check_result "$E_INVALID" "invalid $object_name format :: $1"
	fi
	is_no_new_line_format "$1"
}

# Alias forman validator
is_alias_format_valid() {
	for object in ${1//,/ }; do
		exclude="[!|@|#|$|^|&|(|)|+|=|{|}|:|<|>|?|_|/|\|\"|'|;|%|\`| ]"
		if [[ "$object" =~ $exclude ]]; then
			check_result "$E_INVALID" "invalid alias format :: $object"
		fi
		if [[ "$object" =~ [*] ]] && ! [[ "$object" =~ ^[*]\..* ]]; then
			check_result "$E_INVALID" "invalid alias format :: $object"
		fi
	done
}

# IP format validator
is_ip_format_valid() {
	object_name=${2-ip}
	ip_regex='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
	ip_clean=$(echo "${1%/*}")
	if ! [[ $ip_clean =~ ^$ip_regex\.$ip_regex\.$ip_regex\.$ip_regex$ ]]; then
		check_result "$E_INVALID" "invalid $object_name format :: $1"
	fi
	if [ $1 != "$ip_clean" ]; then
		ip_cidr="$ip_clean/"
		ip_cidr=$(echo "${1#$ip_cidr}")
		if [[ "$ip_cidr" -gt 32 ]] || [[ "$ip_cidr" =~ [:alnum:] ]]; then
			check_result "$E_INVALID" "invalid $object_name format :: $1"
		fi
	fi
}

# IPv6 format validator
is_ipv6_format_valid() {
	object_name=${2-ipv6}
	ip_regex='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
	t_ip=$(echo $1 | awk -F / '{print $1}')
	t_cidr=$(echo $1 | awk -F / '{print $2}')
	valid_cidr=1

	WORD="[0-9A-Fa-f]\{1,4\}"
	# flat address, no compressed words
	FLAT="^${WORD}\(:${WORD}\)\{7\}$"

	COMP2="^\(${WORD}:\)\{1,1\}\(:${WORD}\)\{1,6\}$"
	COMP3="^\(${WORD}:\)\{1,2\}\(:${WORD}\)\{1,5\}$"
	COMP4="^\(${WORD}:\)\{1,3\}\(:${WORD}\)\{1,4\}$"
	COMP5="^\(${WORD}:\)\{1,4\}\(:${WORD}\)\{1,3\}$"
	COMP6="^\(${WORD}:\)\{1,5\}\(:${WORD}\)\{1,2\}$"
	COMP7="^\(${WORD}:\)\{1,6\}\(:${WORD}\)\{1,1\}$"
	# trailing :: edge case, includes case of only :: (all 0's)
	EDGE_TAIL="^\(\(${WORD}:\)\{1,7\}\|:\):$"
	# leading :: edge case
	EDGE_LEAD="^:\(:${WORD}\)\{1,7\}$"

	echo $t_ip | grep --silent "\(${FLAT}\)\|\(${COMP2}\)\|\(${COMP3}\)\|\(${COMP4}\)\|\(${COMP5}\)\|\(${COMP6}\)\|\(${COMP7}\)\|\(${EDGE_TAIL}\)\|\(${EDGE_LEAD}\)"
	if [ $? -ne 0 ]; then
		check_result "$E_INVALID" "invalid $object_name format :: $1"
	fi

	if [ -n "$(echo $1 | grep '/')" ]; then
		if [[ "$t_cidr" -lt 0 ]] || [[ "$t_cidr" -gt 128 ]]; then
			valid_cidr=0
		fi
		if ! [[ "$t_cidr" =~ ^[0-9]+$ ]]; then
			valid_cidr=0
		fi
	fi
	if [ "$valid_cidr" -eq 0 ]; then
		check_result "$E_INVALID" "invalid $object_name format :: $1"
	fi
}

is_ip46_format_valid() {
	t_ip=$(echo $1 | awk -F / '{print $1}')
	t_cidr=$(echo $1 | awk -F / '{print $2}')
	valid_octets=0
	valid_cidr=1
	for octet in ${t_ip//./ }; do
		if [[ $octet =~ ^[0-9]{1,3}$ ]] && [[ $octet -le 255 ]]; then
			((++valid_octets))
		fi
	done

	if [ -n "$(echo $1 | grep '/')" ]; then
		if [[ "$t_cidr" -lt 0 ]] || [[ "$t_cidr" -gt 32 ]]; then
			valid_cidr=0
		fi
		if ! [[ "$t_cidr" =~ ^[0-9]+$ ]]; then
			valid_cidr=0
		fi
	fi
	if [ "$valid_octets" -lt 4 ] || [ "$valid_cidr" -eq 0 ]; then
		#Check IPV6
		ipv6_valid=""
		WORD="[0-9A-Fa-f]\{1,4\}"
		# flat address, no compressed words
		FLAT="^${WORD}\(:${WORD}\)\{7\}$"

		COMP2="^\(${WORD}:\)\{1,1\}\(:${WORD}\)\{1,6\}$"
		COMP3="^\(${WORD}:\)\{1,2\}\(:${WORD}\)\{1,5\}$"
		COMP4="^\(${WORD}:\)\{1,3\}\(:${WORD}\)\{1,4\}$"
		COMP5="^\(${WORD}:\)\{1,4\}\(:${WORD}\)\{1,3\}$"
		COMP6="^\(${WORD}:\)\{1,5\}\(:${WORD}\)\{1,2\}$"
		COMP7="^\(${WORD}:\)\{1,6\}\(:${WORD}\)\{1,1\}$"
		# trailing :: edge case, includes case of only :: (all 0's)
		EDGE_TAIL="^\(\(${WORD}:\)\{1,7\}\|:\):$"
		# leading :: edge case
		EDGE_LEAD="^:\(:${WORD}\)\{1,7\}$"

		echo $t_ip | grep --silent "\(${FLAT}\)\|\(${COMP2}\)\|\(${COMP3}\)\|\(${COMP4}\)\|\(${COMP5}\)\|\(${COMP6}\)\|\(${COMP7}\)\|\(${EDGE_TAIL}\)\|\(${EDGE_LEAD}\)"
		if [ $? -ne 0 ]; then
			ipv6_valid="INVALID"
		fi

		if [ -n "$(echo $1 | grep '/')" ]; then
			if [[ "$t_cidr" -lt 0 ]] || [[ "$t_cidr" -gt 128 ]]; then
				valid_cidr=0
			fi
			if ! [[ "$t_cidr" =~ ^[0-9]+$ ]]; then
				valid_cidr=0
			fi
		fi

		if [ -n "$ipv6_valid" ] || [ "$valid_cidr" -eq 0 ]; then
			check_result "$E_INVALID" "invalid IP format :: $1"
		fi
	fi
}

# Proxy extention format validator
is_extention_format_valid() {
	exclude="[!|#|$|^|&|(|)|+|=|{|}|:|@|<|>|?|/|\|\"|'|;|%|\`| ]"
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "invalid proxy extention format :: $1"
	fi
	is_no_new_line_format "$1"
}

# Number format validator
is_number_format_valid() {
	object_name=${2-number}
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		check_result "$E_INVALID" "invalid $object_name format :: $1"
	fi
}

# Autoreply format validator
is_autoreply_format_valid() {
	if [ 10240 -le ${#1} ]; then
		check_result "$E_INVALID" "invalid autoreply format :: $1"
	fi
}

# Boolean format validator
is_boolean_format_valid() {
	if [ "$1" != 'yes' ] && [ "$1" != 'no' ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Refresh IPset format validator
is_refresh_ipset_format_valid() {
	if [ "$1" != 'load' ] && [ "$1" != 'yes' ] && [ "$1" != 'no' ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Common format validator
is_common_format_valid() {
	exclude="[!|#|$|^|&|(|)|+|=|{|}|:|<|>|?|/|\|\"|'|;|%|\`| ]"
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [ 400 -le ${#1} ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ "$1" =~ @ ]] && [ ${#1} -gt 1 ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ $1 =~ \* ]]; then
		if [[ "$(echo $1 | grep -o '\*\.' | wc -l)" -eq 0 ]] && [[ $1 != '*' ]]; then
			check_result "$E_INVALID" "invalid $2 format :: $1"
		fi
	fi
	if [[ $(echo -n "$1" | tail -c 1) =~ [^a-zA-Z0-9_*@.] ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ $(echo -n "$1" | grep -c '\.\.') -gt 0 ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ $(echo -n "$1" | head -c 1) =~ [^a-zA-Z0-9_*@] ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ $(echo -n "$1" | grep -c '\-\-') -gt 0 ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	if [[ $(echo -n "$1" | grep -c '\_\_') -gt 0 ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	is_no_new_line_format "$1"
}

is_no_new_line_format() {
	test=$(echo "$1" | head -n1)
	if [[ "$test" != "$1" ]]; then
		check_result "$E_INVALID" "invalid value :: $1"
	fi
}

is_string_format_valid() {
	exclude="[!|#|$|^|&|(|)|+|=|{|}|:|<|>|?|/|\|\"|'|;|%|\`]"
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	is_no_new_line_format "$1"
}

# Database format validator
is_database_format_valid() {
	exclude="[!|@|#|$|^|&|*|(|)|+|=|{|}|:|,|<|>|?|/|\|\"|'|;|%|\`| ]"
	if [[ "$1" =~ $exclude ]] || [ 64 -le ${#1} ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	is_no_new_line_format "$1"
}

# Date format validator
is_date_format_valid() {
	if ! [[ "$1" =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$ ]]; then
		check_result "$E_INVALID" "invalid date format :: $1"
	fi
}

# Database user validator
is_dbuser_format_valid() {
	exclude="[!|@|#|$|^|&|*|(|)|+|=|{|}|:|,|<|>|?|/|\|\"|'|;|%|\`| ]"
	if [ 33 -le ${#1} ]; then
		check_result "$E_INVALID" "mysql username can be up to 32 characters long"
	fi
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
	is_no_new_line_format "$1"
}

# DNS record type validator
is_dns_type_format_valid() {
	known_dnstype='A,AAAA,NS,CNAME,MX,TXT,SRV,DNSKEY,KEY,IPSECKEY,PTR,SPF,TLSA,CAA,DS'
	if [ -z "$(echo $known_dnstype | grep -w $1)" ]; then
		check_result "$E_INVALID" "invalid dns record type format :: $1"
	fi
}

# DNS record validator
is_dns_record_format_valid() {
	if [ "$rtype" = 'A' ]; then
		is_ip_format_valid "$1"
	fi
	if [ "$rtype" = 'NS' ]; then
		is_domain_format_valid "${1::-1}" 'ns_record'
	fi
	if [ "$rtype" = 'MX' ]; then
		is_domain_format_valid "${1::-1}" 'mx_record'
		is_int_format_valid "$priority" 'priority_record'
	fi
	if [ "$rtype" = 'SRV' ]; then
		format_no_quotes "$priority" 'priority_record'
	fi

	is_no_new_line_format "$1"
}

# Email format validator
is_email_format_valid() {
	if [[ ! "$1" =~ ^[A-Za-z0-9._%+-]+@[[:alnum:].-]+\.[A-Za-z]{2,63}$ ]]; then
		if [[ ! "$1" =~ ^[A-Za-z0-9._%+-]+@[[:alnum:].-]+\.(xn--)[[:alnum:]]{2,63}$ ]]; then
			check_result "$E_INVALID" "invalid email format :: $1"
		fi
	fi
}

# Firewall action validator
is_fw_action_format_valid() {
	if [ "$1" != "ACCEPT" ] && [ "$1" != 'DROP' ]; then
		check_result "$E_INVALID" "invalid action format :: $1"
	fi
}

# Firewall protocol validator
is_fw_protocol_format_valid() {
	if [ "$1" != "ICMP" ] && [ "$1" != 'UDP' ] && [ "$1" != 'TCP' ]; then
		check_result "$E_INVALID" "invalid protocol format :: $1"
	fi
}

# Firewall port validator
is_fw_port_format_valid() {
	if [ "${#1}" -eq 1 ]; then
		if ! [[ "$1" =~ [0-9] ]]; then
			check_result "$E_INVALID" "invalid port format :: $1"
		fi
	else
		if ! [[ "$1" =~ ^[0-9][-|,|:|0-9]{0,76}[0-9]$ ]]; then
			check_result "$E_INVALID" "invalid port format and/or more than 78 chars used :: $1"
		fi
	fi
}

# DNS record id validator
is_id_format_valid() {
	if ! echo "$1" | grep -qE '^[1-9][0-9]{0,}$'; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Integer validator
is_int_format_valid() {
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Interface validator
is_interface_format_valid() {
	nic_names="$(ip -d -j link show | jq -r '.[] | if .link_type == "loopback" then empty else .ifname, if .altnames then .altnames[] else empty end end')"
	if [ -z "$(echo "$nic_names" | grep -x "$1")" ]; then
		check_result "$E_INVALID" "invalid interface format :: $1"
	fi
}

# IP status validator
is_ip_status_format_valid() {
	if [ -z "$(echo shared,dedicated | grep -w "$1")" ]; then
		check_result "$E_INVALID" "invalid status format :: $1"
	fi
}

# Cron validator
is_cron_format_valid() {
	limit=59
	check_format=''
	if [ "$2" = 'hour' ]; then
		limit=23
	fi

	if [ "$2" = 'day' ]; then
		limit=31
	fi
	if [ "$2" = 'month' ]; then
		limit=12
	fi
	if [ "$2" = 'wday' ]; then
		limit=7
	fi
	if [ "$1" = '*' ]; then
		check_format='ok'
	fi
	if [[ "$1" =~ ^[\*]+[/]+[0-9] ]]; then
		if [ "$(echo $1 | cut -f 2 -d /)" -lt $limit ]; then
			check_format='ok'
		fi
	fi
	if [[ "$1" =~ ^[0-9][-|,|0-9]{0,70}[\/][0-9]$ ]]; then
		check_format='ok'
		crn_values=${1//,/ }
		crn_values=${crn_values//-/ }
		crn_values=${crn_values//\// }
		for crn_vl in $crn_values; do
			if [ "$crn_vl" -gt $limit ]; then
				check_format='invalid'
			fi
		done
	fi
	crn_values=$(echo $1 | tr "," " " | tr "-" " ")
	for crn_vl in $crn_values; do
		if [[ "$crn_vl" =~ ^[0-9]+$ ]] && [ "$crn_vl" -le $limit ]; then
			check_format='ok'
		fi
	done
	if [ "$check_format" != 'ok' ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Validate CPU Quota:
is_valid_cpu_quota() {
	local cpu_quota="$1"
	if [[ ! "$cpu_quota" =~ ^[1-9][0-9]*%$ ]]; then
		check_result "$E_INVALID" "Invalid CPU Quota format: $cpu_quota"
	fi
}

# Validate CPU Quota Period:
is_valid_cpu_quota_period() {
	if [[ ! "$1" =~ ^[0-9]+(ms|s)$ ]]; then
		check_result "$E_INVALID" "Invalid CPU Quota Period format :: $1"
	fi
}

# Validate Memory Size:
is_valid_memory_size() {
	if [[ ! "$1" =~ ^[0-9]+[KMGTK]?$ ]]; then
		check_result "$E_INVALID" "Invalid Memory Size format :: $1"
	fi
}

# Validate Swap Size:
is_valid_swap_size() {
	if [[ ! "$1" =~ ^[0-9]+[KMGTK]?$ ]]; then
		check_result "$E_INVALID" "Invalid Swap Size format :: $1"
	fi
}

is_object_name_format_valid() {
	if ! [[ "$1" =~ ^[-|\ |\.|_[:alnum:]]{0,50}$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}
# Name validator
is_name_format_valid() {
	exclude="['|\"|<|>]"
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "Invalid $2 contains qoutes (\" or ') :: $1"
	fi
	is_no_new_line_format "$1"
}

# Object validator
is_object_format_valid() {
	if ! [[ "$1" =~ ^[[:alnum:]][-|\.|_[:alnum:]]{0,64}[[:alnum:]]$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Role validator
is_role_valid() {
	if ! [[ "$1" =~ ^admin$|^user$|^dns-cluster$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Password validator
is_password_format_valid() {
	if [ "${#1}" -lt '6' ]; then
		check_result "$E_INVALID" "invalid password format :: $1"
	fi
}
# Missing function -
# Before: validate_format_shell
# After: is_format_valid_shell
is_format_valid_shell() {
	if [ -z "$(grep -w $1 /etc/shells)" ]; then
		echo "Error: shell $1 is not valid"
		log_event "$E_INVALID" "$EVENT"
		exit $E_INVALID
	fi
}

# Service name validator
is_service_format_valid() {
	if ! [[ "$1" =~ ^[[:alnum:]][-|\.|_[:alnum:]]{0,64}$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

is_hash_format_valid() {
	if ! [[ "$1" =~ ^[[:alnum:]|\:|\=|_|-]{1,80}$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

# Format validation controller
is_format_valid() {
	for arg_name in $*; do
		eval arg=\$$arg_name
		if [ -n "$arg" ]; then
			case $arg_name in
				access_key_id) is_access_key_id_format_valid "$arg" "$arg_name" ;;
				account) is_localpart_format_valid "$arg" "$arg_name" '64' ;;
				action) is_fw_action_format_valid "$arg" ;;
				active) is_boolean_format_valid "$arg" 'active' ;;
				aliases) is_alias_format_valid "$arg" ;;
				alias) is_alias_format_valid "$arg" ;;
				antispam) is_boolean_format_valid "$arg" 'antispam' ;;
				antivirus) is_boolean_format_valid "$arg" 'antivirus' ;;
				autoreply) is_autoreply_format_valid "$arg" ;;
				backup) is_object_format_valid "$arg" 'backup' ;;
				charset) is_object_format_valid "$arg" "$arg_name" ;;
				charsets) is_common_format_valid "$arg" 'charsets' ;;
				chain) is_object_format_valid "$arg" 'chain' ;;
				comment) is_object_format_valid "$arg" 'comment' ;;
				database) is_database_format_valid "$arg" 'database' ;;
				day) is_cron_format_valid "$arg" $arg_name ;;
				dbpass) is_password_format_valid "$arg" ;;
				dbuser) is_dbuser_format_valid "$arg" 'dbuser' ;;
				dkim) is_boolean_format_valid "$arg" 'dkim' ;;
				dkim_size) is_int_format_valid "$arg" ;;
				domain) is_domain_format_valid "$arg" ;;
				dom_alias) is_alias_format_valid "$arg" ;;
				dvalue) is_dns_record_format_valid "$arg" ;;
				email) is_email_format_valid "$arg" ;;
				email_forward) is_email_format_valid "$arg" ;;
				exp) is_date_format_valid "$arg" ;;
				extentions) is_common_format_valid "$arg" 'extentions' ;;
				format) is_type_valid 'plain json shell csv' "$arg" ;;
				ftp_password) is_password_format_valid "$arg" ;;
				ftp_user) is_user_format_valid "$arg" "$arg_name" ;;
				hash) is_hash_format_valid "$arg" "$arg_name" ;;
				host) is_object_format_valid "$arg" "$arg_name" ;;
				hour) is_cron_format_valid "$arg" $arg_name ;;
				id) is_id_format_valid "$arg" 'id' ;;
				iface) is_interface_format_valid "$arg" ;;
				ip) is_ip_format_valid "$arg" ;;
				ipv6) is_ipv6_format_valid "$arg" ;;
				ip46) is_ip46_format_valid "$arg" ;;
				ip_name) is_domain_format_valid "$arg" 'IP name' ;;
				ip_status) is_ip_status_format_valid "$arg" ;;
				job) is_int_format_valid "$arg" 'job' ;;
				key) is_common_format_valid "$arg" "$arg_name" ;;
				malias) is_localpart_format_valid "$arg" "$arg_name" '64' ;;
				max_db) is_int_format_valid "$arg" 'max db' ;;
				min) is_cron_format_valid "$arg" $arg_name ;;
				month) is_cron_format_valid "$arg" $arg_name ;;
				name) is_name_format_valid "$arg" "name" ;;
				nat_ip) is_ip_format_valid "$arg" ;;
				netmask) is_ip_format_valid "$arg" 'netmask' ;;
				newid) is_int_format_valid "$arg" 'id' ;;
				ns1) is_domain_format_valid "$arg" 'ns1' ;;
				ns2) is_domain_format_valid "$arg" 'ns2' ;;
				ns3) is_domain_format_valid "$arg" 'ns3' ;;
				ns4) is_domain_format_valid "$arg" 'ns4' ;;
				ns5) is_domain_format_valid "$arg" 'ns5' ;;
				ns6) is_domain_format_valid "$arg" 'ns6' ;;
				ns7) is_domain_format_valid "$arg" 'ns7' ;;
				ns8) is_domain_format_valid "$arg" 'ns8' ;;
				object) is_object_name_format_valid "$arg" 'object' ;;
				package) is_object_format_valid "$arg" "$arg_name" ;;
				password) is_password_format_valid "$arg" ;;
				priority) is_int_format_valid $arg ;;
				port) is_int_format_valid "$arg" 'port' ;;
				port_ext) is_fw_port_format_valid "$arg" ;;
				protocol) is_fw_protocol_format_valid "$arg" ;;
				proxy_ext) is_extention_format_valid "$arg" ;;
				proxy_url) is_proxy_url_valid "$arg" ;;
				quota) is_int_format_valid "$arg" 'quota' ;;
				rate) is_int_format_valid "$arg" 'rate' ;;
				record) is_common_format_valid "$arg" 'record' ;;
				reject) is_boolean_format_valid "$arg" 'reject' ;;
				restart) is_restart_format_valid "$arg" 'restart' ;;
				role) is_role_valid "$arg" 'role' ;;
				rtype) is_dns_type_format_valid "$arg" ;;
				rule) is_int_format_valid "$arg" "rule id" ;;
				service) is_service_format_valid "$arg" "$arg_name" ;;
				secret_access_key) is_secret_access_key_format_valid "$arg" "$arg_name" ;;
				soa) is_domain_format_valid "$arg" 'SOA' ;;
				#missing command: is_format_valid_shell
				shell) is_format_valid_shell "$arg" ;;
				ssl_dir) is_folder_exists "$arg" "$arg_name" ;;
				stats_pass) is_password_format_valid "$arg" ;;
				stats_user) is_user_format_valid "$arg" "$arg_name" ;;
				template) is_object_format_valid "$arg" "$arg_name" ;;
				theme) is_common_format_valid "$arg" "$arg_name" ;;
				ttl) is_int_format_valid "$arg" 'ttl' ;;
				user) is_user_format_valid "$arg" $arg_name ;;
				wday) is_cron_format_valid "$arg" $arg_name ;;
				value) is_common_format_valid "$arg" $arg_name ;;
			esac
		fi
	done
}

is_folder_exists() {
	if [ ! -d "$1" ]; then
		check_result "$E_NOTEXIST" "folder $1 does not exist"
	fi
}

is_command_valid_format() {
	if [[ ! "$1" =~ ^v-[[:alnum:]][-|\.|_[:alnum:]]{0,64}[[:alnum:]]$ ]]; then
		check_result "$E_INVALID" "Invalid command format"
	fi
	if [[ -n $(echo "$1" | grep -e '\-\-') ]]; then
		check_result "$E_INVALID" "Invalid command format"
	fi
}
# Check access_key_id name
# Don't work with legacy key format
is_access_key_id_format_valid() {
	local hash="$1"

	# ACCESS_KEY_ID format validation
	if ! [[ "$hash" =~ ^[[:alnum:]]{20}$ ]]; then
		check_result "$E_INVALID" "invalid $2 format :: $hash"
	fi
}

# SECRET_ACCESS_KEY format validation
is_secret_access_key_format_valid() {
	local hash="$1"

	if ! [[ "$hash" =~ ^[[:alnum:]|_|\.|\+|/|\^|~|=|%|\-]{40}$ ]]; then
		check_result "$E_INVALID" "invalid $2 format"
	fi
}

# Checks if the secret belongs to the access key
check_access_key_secret() {
	local access_key_id="$(basename "$1")"
	local secret_access_key=$2
	local -n key_user=$3

	if [[ -z "$access_key_id" || ! -f "$HESTIA/data/access-keys/${access_key_id}" ]]; then
		check_result "$E_PASSWORD" "Access key $access_key_id doesn't exist"
	fi

	if [[ -z "$secret_access_key" ]]; then
		check_result "$E_PASSWORD" "Secret key not provided for key $access_key_id"
	elif ! [[ "$secret_access_key" =~ ^[[:alnum:]|_|\.|\+|/|\^|~|=|%|\-]{40}$ ]]; then
		check_result "$E_PASSWORD" "Invalid secret key for key $access_key_id"
	else
		SECRET_ACCESS_KEY=""
		source_conf "$HESTIA/data/access-keys/${access_key_id}"

		if [[ -z "$SECRET_ACCESS_KEY" || "$SECRET_ACCESS_KEY" != "$secret_access_key" ]]; then
			check_result "$E_PASSWORD" "Invalid secret key for key $access_key_id"
		fi
	fi

	key_user="$USER"
}

# Checks if the key belongs to the user
check_access_key_user() {
	local access_key_id="$(basename "$1")"
	local user=$2

	if [[ -z "$access_key_id" || ! -f "$HESTIA/data/access-keys/${access_key_id}" ]]; then
		check_result "$E_FORBIDEN" "Access key $access_key_id doesn't exist"
	fi

	if [[ -z "$user" ]]; then
		check_result "$E_FORBIDEN" "User not provided"
	else
		USER=""
		source_conf "$HESTIA/data/access-keys/${access_key_id}"

		if [[ -z "$USER" || "$USER" != "$user" ]]; then
			check_result "$E_FORBIDEN" "key $access_key_id does not belong to the user $user"
		fi
	fi
}

# Checks if the key is allowed to run the command
check_access_key_cmd() {
	local access_key_id="$(basename "$1")"
	local cmd=$2
	local -n user_arg_position=$3

	if [[ "$DEBUG_MODE" = "true" ]]; then
		new_timestamp
		echo "[$date:$time] $1 $2" >> /var/log/hestia/api.log
	fi
	if [[ -z "$access_key_id" || ! -f "$HESTIA/data/access-keys/${access_key_id}" ]]; then
		check_result "$E_FORBIDEN" "Access key $access_key_id doesn't exist"
	fi

	if [[ -z "$cmd" ]]; then
		check_result "$E_FORBIDEN" "Command not provided"
	elif [[ "$cmd" = 'v-make-tmp-file' ]]; then
		USER="" PERMISSIONS=""
		source_conf "${HESTIA}/data/access-keys/${access_key_id}"
		local allowed_commands
		if [[ -n "$PERMISSIONS" ]]; then
			allowed_commands="$(get_apis_commands "$PERMISSIONS")"
			if [[ -z "$(echo ",${allowed_commands}," | grep ",${hst_command},")" ]]; then
				check_result "$E_FORBIDEN" "Key $access_key_id don't have permission to run the command $hst_command"
			fi
		elif [[ -z "$PERMISSIONS" && "$USER" != "$ROOT_USER" ]]; then
			check_result "$E_FORBIDEN" "Key $access_key_id don't have permission to run the command $hst_command"
		fi
		user_arg_position="0"
	elif [[ ! -e "$BIN/$cmd" ]]; then
		check_result "$E_FORBIDEN" "Command $cmd not found"
	else
		USER="" PERMISSIONS=""
		source_conf "${HESTIA}/data/access-keys/${access_key_id}"

		local allowed_commands
		if [[ -n "$PERMISSIONS" ]]; then
			allowed_commands="$(get_apis_commands "$PERMISSIONS")"
			if [[ -z "$(echo ",${allowed_commands}," | grep ",${hst_command},")" ]]; then
				check_result "$E_FORBIDEN" "Key $access_key_id don't have permission to run the command $hst_command"
			fi
		elif [[ -z "$PERMISSIONS" && "$USER" != "$ROOT_USER" ]]; then
			check_result "$E_FORBIDEN" "Key $access_key_id don't have permission to run the command $hst_command"
		fi

		if [[ "$USER" == "$ROOT_USER" ]]; then
			# Admin can run commands for any user
			user_arg_position="0"
		else
			user_arg_position="$(search_command_arg_position "$hst_command" "USER")"
			if ! [[ "$user_arg_position" =~ ^[0-9]+$ ]]; then
				check_result "$E_FORBIDEN" "Command $hst_command not found"
			fi
		fi
	fi
}

# Domain argument formatting
format_domain() {
	if [[ "$domain" = *[![:ascii:]]* ]]; then
		if [[ "$domain" =~ [[:upper:]] ]]; then
			domain=$(echo "$domain" | sed 's/[[:upper:]].*/\L&/')
		fi
	else
		if [[ "$domain" =~ [[:upper:]] ]]; then
			domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')
		fi
	fi
	if [[ "$domain" =~ ^www\..* ]]; then
		domain=$(echo "$domain" | sed -e "s/^www.//")
	fi
	if [[ "$domain" =~ .*\.$ ]]; then
		domain=$(echo "$domain" | sed -e "s/[.]*$//g")
	fi
	if [[ "$domain" =~ ^\. ]]; then
		domain=$(echo "$domain" | sed -e "s/^[.]*//")
	fi
	# Remove white spaces
	domain=$(echo $domain | sed 's/^[ \t]*//;s/[ \t]*$//')
}

format_domain_idn() {
	if [ -z "$domain_idn" ]; then
		domain_idn=$domain
	fi
	if [[ "$domain_idn" = *[![:ascii:]]* ]]; then
		domain_idn=$(idn2 --quiet $domain_idn)
	fi
}

format_aliases() {
	if [ -n "$aliases" ] && [ "$aliases" != 'none' ]; then
		aliases=$(echo $aliases | tr '[:upper:]' '[:lower:]' | tr ',' '\n')
		aliases=$(echo "$aliases" | sed -e "s/\.$//" | sort -u)
		aliases=$(echo "$aliases" | tr -s '.')
		aliases=$(echo "$aliases" | sed -e "s/[.]*$//g")
		aliases=$(echo "$aliases" | sed -e "s/^[.]*//")
		aliases=$(echo "$aliases" | sed -e "/^$/d")
		aliases=$(echo "$aliases" | tr '\n' ',' | sed -e "s/,$//")
	fi
}

is_restart_format_valid() {
	if [ "$1" != 'yes' ] && [ "$1" != 'no' ] && [ "$1" != 'ssl' ] && [ "$1" != 'reload' ] && [ "$1" != 'updatessl' ]; then
		check_result "$E_INVALID" "invalid $2 format :: $1"
	fi
}

check_backup_conditions() {
	# Checking load average
	la=$(cat /proc/loadavg | cut -f 1 -d ' ' | cut -f 1 -d '.')
	# i=0
	while [ "$la" -ge "$BACKUP_LA_LIMIT" ]; do
		echo -e "$(date "+%F %T") Load Average $la"
		sleep 60
		la=$(cat /proc/loadavg | cut -f 1 -d ' ' | cut -f 1 -d '.')
	done
}

# Define download function
download_file() {
	local url=$1
	local destination=$2
	local force=$3

	# Default destination is the curent working directory
	local dstopt=""

	if [ -n "$(echo "$url" | grep -E "\.(gz|gzip|bz2|zip|xz)$")" ]; then
		# When an archive file is downloaded it will be first saved localy
		dstopt="--directory-prefix=$ARCHIVE_DIR"
		local is_archive="true"
		local filename="${url##*/}"
		if [ -z "$filename" ]; then
			echo >&2 "[!] No filename was found in url, exiting ($url)"
			exit 1
		fi
		if [ -n "$force" ] && [ -f "$ARCHIVE_DIR/$filename" ]; then
			rm -f $ARCHIVE_DIR/$filename
		fi
	elif [ -n "$destination" ]; then
		# Plain files will be written to specified location
		dstopt="-O $destination"
	fi
	# check for corrupted archive
	if [ -f "$ARCHIVE_DIR/$filename" ] && [ "$is_archive" = "true" ]; then
		tar -tzf "$ARCHIVE_DIR/$filename" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo >&2 "[!] Archive $ARCHIVE_DIR/$filename is corrupted, redownloading"
			rm -f $ARCHIVE_DIR/$filename
		fi
	fi

	if [ ! -f "$ARCHIVE_DIR/$filename" ]; then
		wget $url -q $dstopt --show-progress --progress=bar:force --limit-rate=3m
	fi

	if [ -n "$destination" ] && [ "$is_archive" = "true" ]; then
		if [ "$destination" = "-" ]; then
			cat "$ARCHIVE_DIR/$filename"
		elif [ -d "$(dirname $destination)" ]; then
			cp "$ARCHIVE_DIR/$filename" "$destination"
		fi
	fi
}

check_hestia_demo_mode() {
	demo_mode=$(grep DEMO_MODE /usr/local/hestia/conf/hestia.conf | cut -d '=' -f2 | sed "s|'||g")
	if [ -n "$demo_mode" ] && [ "$demo_mode" = "yes" ]; then
		echo "ERROR: Unable to perform operation due to security restrictions that are in place."
		exit 1
	fi
}

multiphp_count() {
	$BIN/v-list-sys-php plain | wc -l
}

multiphp_versions() {
	local -a php_versions_list
	local php_ver
	if [ "$(multiphp_count)" -gt 0 ]; then
		for php_ver in $($BIN/v-list-sys-php plain); do
			[ ! -d "/etc/php/$php_ver/fpm/pool.d/" ] && continue
			php_versions_list+=($php_ver)
		done
		echo "${php_versions_list[@]}"
	fi
}

multiphp_default_version() {
	# Get system wide default php version (set by update-alternatives)
	local sys_phpversion=$(php -r "echo substr(phpversion(),0,3);")

	# Check if the system php also has php-fpm enabled, otherwise return
	# the most recent php version which does have it installed.
	if [ ! -d "/etc/php/$sys_phpversion/fpm/pool.d/" ]; then
		local all_versions="$(multiphp_versions)"
		if [ -n "$all_versions" ]; then
			sys_phpversion="${all_versions##*\ }"
		fi
	fi

	echo "$sys_phpversion"
}

is_hestia_package() {
	check=false
	for pkg in $1; do
		if [ "$pkg" == "$2" ]; then
			check="true"
		fi
	done
	if [ "$check" != "true" ]; then
		check_result $E_INVALID "$2 package is not controlled by hestiacp"
	fi
}

# Run arbitrary cli commands with dropped privileges
# Note: setpriv --init-groups is not available on debian9 (util-linux 2.29.2)
# Input:
#     - $user : Vaild hestia user
user_exec() {
	is_object_valid 'user' 'USER' "$user"

	local user_groups=$(id -G "$user")
	user_groups=${user_groups//\ /,}

	setpriv --groups "$user_groups" --reuid "$user" --regid "$user" -- "${@}"
}

# Simple chmod wrapper that skips symlink files after glob expand
no_symlink_chmod() {
	local filemode=$1
	shift

	for i in "$@"; do
		[[ -L ${i} ]] && continue

		chmod "${filemode}" "${i}"
	done
}

format_no_quotes() {
	exclude="['|\"]"
	if [[ "$1" =~ $exclude ]]; then
		check_result "$E_INVALID" "Invalid $2 contains qoutes (\" or ' or | ) :: $1"
	fi
	is_no_new_line_format "$1"
}

is_username_format_valid() {
	if [[ ! "$1" =~ ^[A-Za-z0-9._%+-]+@[[:alnum:].-]+\.[A-Za-z]{2,63}$ ]]; then
		is_string_format_valid "$1" "$2"
	fi
}

change_sys_value() {
	check_ckey=$(grep "^$1='" "$HESTIA/conf/hestia.conf")
	if [ -z "$check_ckey" ]; then
		echo "$1='$2'" >> "$HESTIA/conf/hestia.conf"
	else
		sed -i "s|^$1=.*|$1='$2'|g" "$HESTIA/conf/hestia.conf"
	fi
}

# Checks the format of APIs that will be allowed for the key
is_key_permissions_format_valid() {
	local permissions="$1"
	local user="$2"

	if [[ "$user" != "$ROOT_USER" && -z "$permissions" ]]; then
		check_result "$E_INVALID" "Non-admin users need a permission list"
	fi

	while IFS=',' read -ra permissions_arr; do
		for permission in "${permissions_arr[@]}"; do
			permission="$(basename "$permission" | sed -E "s/^\s*|\s*$//g")"

			#            if [[ -z "$(echo "$permission" | grep -E "^v-")" ]]; then
			if [[ ! -e "$HESTIA/data/api/$permission" ]]; then
				check_result "$E_NOTEXIST" "API $permission doesn't exist"
			fi

			source_conf "$HESTIA/data/api/$permission"
			if [ "$ROLE" = "admin" ] && [ "$user" != "$ROOT_USER" ]; then
				check_result "$E_INVALID" "Only the admin can run this API"
			fi
			#            elif [[ ! -e "$BIN/$permission" ]]; then
			#                check_result "$E_NOTEXIST" "Command $permission doesn't exist"
			#            fi
		done
	done <<< "$permissions"
}

# Remove whitespaces, and bin path from commands
cleanup_key_permissions() {
	local permissions="$1"

	local final quote
	while IFS=',' read -ra permissions_arr; do
		for permission in "${permissions_arr[@]}"; do
			permission="$(basename "$permission" | sed -E "s/^\s*|\s*$//g")"

			# Avoid duplicate items
			if [[ -z "$(echo ",${final}," | grep ",${permission},")" ]]; then
				final+="${quote}${permission}"
				quote=','
			fi
		done
	done <<< "$permissions"

	echo "$final"
}

# Extract all allowed commands from a permission list
get_apis_commands() {
	local permissions="$1"

	local allowed_commands quote commands_to_add
	while IFS=',' read -ra permissions_arr; do
		for permission in "${permissions_arr[@]}"; do
			permission="$(basename "$permission" | sed -E "s/^\s*|\s*$//g")"

			commands_to_add=""
			#            if [[ -n "$(echo "$permission" | grep -E "^v-")" ]]; then
			#                commands_to_add="$permission"
			#            el
			if [[ -e "$HESTIA/data/api/$permission" ]]; then
				source_conf "$HESTIA/data/api/$permission"
				commands_to_add="$COMMANDS"
			fi

			if [[ -n "$commands_to_add" ]]; then
				allowed_commands+="${quote}${commands_to_add}"
				quote=','
			fi
		done
	done <<< "$permissions"

	cleanup_key_permissions "$allowed_commands"
}

# Get the position of an argument by name in a hestia command using the command's documentation comment.
#
# Return:
# * 0:   It doesn't have the argument;
# * 1-9: The position of the argument in the command.
search_command_arg_position() {
	local hst_command="$(basename "$1")"
	local arg_name="$2"

	local command_path="$BIN/$hst_command"
	if [[ -z "$hst_command" || ! -e "$command_path" ]]; then
		echo "-1"
		return
	fi

	local position=0
	local count=0
	local command_options="$(sed -En 's/^# options: (.+)/\1/p' "$command_path")"
	while IFS=' ' read -ra options_arr; do
		for option in "${options_arr[@]}"; do
			count=$((count + 1))

			option_name="$(echo "  $option   " | sed -E 's/^(\s|\[)*|(\s|\])*$//g')"
			if [[ "${option_name^^}" == "$arg_name" ]]; then
				position=$count
			fi
		done
	done <<< "$command_options"

	echo "$position"
}

add_chroot_jail() {
	local user=$1

	mkdir -p /srv/jail/$user
	chown 0:0 /srv /srv/jail /srv/jail/$user
	chmod 755 /srv /srv/jail /srv/jail/$user
	if [ ! -d /srv/jail/$user/home ]; then
		mkdir -p /srv/jail/$user/home
		chown 0:0 /srv/jail/$user/home
		chmod 755 /srv/jail/$user/home
	fi
	if [ ! -d /srv/jail/$user/home/$user ]; then
		mkdir -p /srv/jail/$user/home/$user
		chown 0:0 /srv/jail/$user/home/$user
		chmod 755 /srv/jail/$user/home/$user
	fi

	systemd=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home/$user")
	cat > "/etc/systemd/system/$systemd" << EOF
[Unit]
Description=Mount $user's home directory to the jail chroot
Before=local-fs.target

[Mount]
What=$(getent passwd $user | cut -d : -f 6)
Where=/srv/jail/$user/home/$user
Type=none
Options=bind
LazyUnmount=yes

[Install]
RequiredBy=local-fs.target
EOF

	systemctl daemon-reload > /dev/null 2>&1
	systemctl enable "$systemd" > /dev/null 2>&1
	systemctl start "$systemd" > /dev/null 2>&1
}

delete_chroot_jail() {
	local user=$1

	# Backwards compatibility with old style home jail
	systemd=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home")
	systemctl stop "$systemd" > /dev/null 2>&1
	systemctl disable "$systemd" > /dev/null 2>&1
	rm -f "/etc/systemd/system/$systemd"

	# Remove the new style home jail
	systemd=$(systemd-escape -p --suffix=mount "/srv/jail/$user/home/$user")
	systemctl stop "$systemd" > /dev/null 2>&1
	systemctl disable "$systemd" > /dev/null 2>&1
	rm -f "/etc/systemd/system/$systemd"

	systemctl daemon-reload > /dev/null 2>&1
	rm -r /srv/jail/$user/ > /dev/null 2>&1
	rmdir /srv/jail/$user > /dev/null 2>&1
}
