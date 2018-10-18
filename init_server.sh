#!/usr/bin/env bash
#version 0.0.8
###
#
#  Freifunk Dresden Server - Installation & Update Script
#
###

#
# -- Global Parameter --
#

export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

INSTALL_DIR='/srv/ffdd-server'


# function: find default gateway interface
get_default_interface() {
	def_if="$(ip ro lis | awk '/default/ { print $5 }')"
}

#
# -- Check & Setup System --
#

# check root permission
if [ "$EUID" -ne 0 ]; then printf 'Please run as root!\n'; exit 0; fi

# check Distribution
if [ -f /etc/debian_version ]; then
	PKGMNGR='apt-get';
elif [ -f /etc/centos-release ] ; then
	printf 'Centos is not supported yet!\n'; exit 0;
	#PKGMNGR='yum'
elif [ -f /etc/fedora-release ] ; then
	printf 'Fedora is not supported yet!\n'; exit 0;
	#PKGMNGR='dnf'
else
	printf 'OS not supported yet!\n'; exit 0;
fi


# update system
printf '\n### Update System ..\n';

"$PKGMNGR" update
"$PKGMNGR" -y upgrade
"$PKGMNGR" -y --fix-missing install
"$PKGMNGR" -y dist-upgrade
"$PKGMNGR" -y --fix-broken install

# install basic software
printf '\n### Instaĺl Basic Software..\n';

"$PKGMNGR" -y install git salt-minion


# check users are present
printf '\n### Check users are present..\n';

for users in freifunk syslog
do
	if ! /usr/bin/id "$users" >/dev/null 2>&1 ; then
		adduser --shell /bin/bash --disabled-login --disabled-password --system --group --no-create-home "$users"
	fi
done


# install/update repository
printf '\n### Install/Update Repository..\n';

if [ ! -d "$INSTALL_DIR" ]; then
	git clone https://github.com/cremesk/ffdd-server.git "$INSTALL_DIR"
else
	cd "$INSTALL_DIR" ; git pull origin master
fi


# small salt fix to create templates (replace: false)
cp /root/.bashrc /root/.bashrc_bak >/dev/null 2>&1
rm /root/.bashrc >/dev/null 2>&1
rm /etc/issue.net >/dev/null 2>&1


# ensure nvram and nvram.conf are present and correct
printf '\n### Check "nvram" Setup ..\n';

	if [ ! -f /usr/local/bin/nvram ]; then
		cp -v "$INSTALL_DIR"/salt/freifunk/base/nvram/usr/local/bin/nvram /usr/local/bin/
	fi

	if [ ! -f /etc/nvram.conf ]; then
		printf '\n### Create New /etc/nvram.conf and /usr/local/bin/nvram\n';

		cp -v "$INSTALL_DIR"/salt/freifunk/base/nvram/etc/nvram.conf /etc/nvram.conf

	else
		printf '\n### /etc/nvram.conf exists.\n';
		printf '### Create /etc/nvram.conf.default & /etc/nvram.conf.diff\n';
		NOTICE="$(printf '\n# Notice: Please check config options in /etc/nvram.conf & /etc/nvram.conf.diff !\n')"

		# check new options are set
		au="$(grep -c autoupdate < /etc/nvram.conf)"
		insdir="$(grep -c install_dir < /etc/nvram.conf)"

		# check autoupdate
		if [ "$au" -lt 1 ]; then
			sed -i '1s/^/\nautoupdate=1\n\n/' /etc/nvram.conf
			sed -i '1s/^/\n# set autoupdate (0=off 1=on)/' /etc/nvram.conf
		fi
		# check install path
		if [ "$insdir" -lt 1 ]; then
			{ echo "install_dir=$INSTALL_DIR"; cat /etc/nvram.conf; } >/etc/nvram.conf.new
				mv /etc/nvram.conf.new /etc/nvram.conf
		fi

		cp -fv "$INSTALL_DIR"/salt/freifunk/base/nvram/etc/nvram.conf /etc/nvram.conf.default
		diff /etc/nvram.conf.default /etc/nvram.conf > /etc/nvram.conf.diff
	fi

	# check default Interface is correct set
	get_default_interface
	if [ "$(nvram get ifname)" != "$def_if" ]; then
		nvram set ifname "$def_if"
	fi

	# check install_dir is correct set
	if [ "$(nvram get install_dir)" != "$INSTALL_DIR" ]; then
		nvram set install_dir "$INSTALL_DIR"
	fi


# create clean salt enviroment
printf '\n### Check Salt Enviroment ..\n';

rm -f /etc/salt/minion.d/*.conf

cat > /etc/salt/minion.d/freifunk-masterless.conf <<EOF
file_client: local
file_roots:
  base:
    - $INSTALL_DIR/salt/freifunk/base
EOF


# ensure running services are stopped
printf '\n### Ensure Services are Stopped ..\n';
for services in S90iperf3 apache2 S52batmand S53backbone-fastd2 openvpn@openvpn S40network S42firewall6 S41firewall
do
	# check service exists
	if [ "$(systemctl list-unit-files | grep -c $services)" -ge 1 ]; then
		# true: stop it
		if [ "$(systemctl status $services | grep -c running)" -ge 1 ]; then
			systemctl stop "$services" >/dev/null 2>&1
		fi
	fi
done


#
# -- Initial System --
#

printf '\n### Start Initial System. (please wait!)\n';

salt-call state.highstate --local


#
# -- Cleanup System --
#

printf '\n### .. All done! Cleanup System ..\n';

"$PKGMNGR" autoremove

printf '%s\n' "$NOTICE"


# Exit gracefully.
exit 0
