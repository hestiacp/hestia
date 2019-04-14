#!/bin/bash
# Hestia installation wrapper
# https://hestiacp.com

#
# Currently Supported Operating Systems:
#
#   Debian 8, 9
#   Ubuntu 14.04, 16.04, 18.04
#

#
# Application Functions
#

check_root(){
	# Am I root?
	if [ "x$(id -u)" != 'x0' ]; then
		echo 'Error: this script can only be executed by root'
		exit 1
	fi
}

check_adm_user(){
	# Check admin user account
	if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ -z "$1" ]; then
		echo "Error: user admin exists"
		echo
		echo 'Please remove admin user before proceeding.'
		echo 'If you want to do it automatically run installer with -f option:'
		echo "Example: bash $0 --force"
		exit 1
	fi
}

check_adm_gp(){
	# Check admin group
	if [ ! -z "$(grep ^admin: /etc/group)" ] && [ -z "$1" ]; then
		echo "Error: group admin exists"
		echo
		echo 'Please remove admin group before proceeding.'
		echo 'If you want to do it automatically run installer with -f option:'
		echo "Example: bash $0 --force"
		exit 1
	fi
}

detect_os(){
	# Detect OS
	case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
		Debian)     type="debian" ;;
		Ubuntu)     type="ubuntu" ;;
		*)          type="NoSupport" ;;
	esac
}

no_support_message(){
	echo "Your OS is currently not supported."
	exit 1;
}

system_unsupported(){
	# Check if OS is supported
	if [ "$type" = "NoSupport" ]; then
		no_support_message
	fi
}

check_wget_curl(){
	# Check wget
	if [ -e '/usr/bin/wget' ]; then
		wget -q https://raw.githubusercontent.com/hestiacp/hestiacp/master/install/hst-install-$type.sh -O hst-install-$type.sh
		if [ "$?" -eq '0' ]; then
			bash hst-install-$type.sh $*
			exit
		else
			echo "Error: hst-install-$type.sh download failed."
			exit 1
		fi
	fi

	# Check curl
	if [ -e '/usr/bin/curl' ]; then
		curl -s -O https://raw.githubusercontent.com/hestiacp/hestiacp/master/install/hst-install-$type.sh
		if [ "$?" -eq '0' ]; then
			bash hst-install-$type.sh $*
			exit
		else
			echo "Error: hst-install-$type.sh download failed."
			exit 1
		fi
	fi
}

detect_release_version(){
	# Detect release version
	if [ "$type" = "debian" ]; then
		codename="$(cat /etc/os-release |grep VERSION= |cut -f 2 -d \(|cut -f 1 -d \))"
		release=$(cat /etc/debian_version|grep -o [0-9]|head -n1)
		VERSION='debian'

		# Check Debian Version Are Acceptable to install
		if [[ $release = '8' ]] || [[ $release = '9' ]]; then
			check_wget_curl
		else
			no_support_message
		fi
	fi

	if [ "$type" = "ubuntu" ]; then
		codename="$(lsb_release -s -c)"
		release="$(lsb_release -s -r)"
		VERSION='ubuntu'

		# Check Ubuntu Version Are Acceptable to install
		if [[ $release = '14.04' ]] || [[ $release = '16.04' ]] || [[ $release = '18.04' ]]; then
			check_wget_curl
		else
			no_support_message
		fi
	fi

	exit
}

application(){
	check_root
	check_adm_user
	check_adm_gp
	detect_os
	system_unsupported
	detect_release_version
}

application
