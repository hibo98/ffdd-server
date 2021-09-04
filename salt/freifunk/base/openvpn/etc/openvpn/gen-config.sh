#!/usr/bin/env bash
### This file managed by Salt, do not edit by hand! ###
# modifies openvpn config to match firmware requirements

print_help() {
	printf 'usage: gen-config.sh [vpn0|vpn1] config-file\n'
	exit 1
}

set_vpn_if() {
	# $1 - interface number
	vpn="vpn$1"
	CONF="/etc/openvpn/openvpn-$vpn.conf"
}

case "$#" in
	2)
		case "$1" in
			vpn0)	set_vpn_if 0 ;;
			vpn1)	set_vpn_if 1 ;;
			*) print_help ;;
		esac
		shift # shift to next param (config file name)
		;;
	1) set_vpn_if 0 ;;
	*) print_help ;;
esac

input="$1"

printf "# generated by $(pwd)/$(basename $0)\n" > "$CONF"

cat "$input" | sed '
s#^[	 ]*##
s/#.*$//
s#[ 	]*$##
/^$/d
/^#/d
/^dev/d
/^persist-key/d
/^persist-tun/d
/^keepalive/d
/^verb/d
/^script/d
/^up/d
/^down/d
/^route/d
/^ifconfig/d
/^resolv/d
/^float/d
/^dhcp-renew/d
/^dhcp-release/d
/^explicit-exit-notify/d
/^ping/d
/^pull-filter/d
/^auth-nocache/d
s#^auth-user-pass.*#auth-user-pass openvpn.login#
' >> "$CONF"

#add newline
cat<<EOM >> "$CONF"

dev $vpn
dev-type tun
resolv-retry infinite
keepalive 10 30
script-security 2
mute-replay-warnings
auth-nocache
float
route-noexec
ifconfig-noexec
up /etc/openvpn/up.sh
down /etc/openvpn/down.sh
verb 3
EOM

# ensure correct rights
chmod 640 "$CONF"
