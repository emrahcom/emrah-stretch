#!/bin/bash

# -----------------------------------------------------------------------------
# HOST.SH
# -----------------------------------------------------------------------------
set -e

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_HOST" = true ] && exit
cd $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER

echo
echo "-------------------------- HOST ---------------------------"

# -----------------------------------------------------------------------------
# BACKUP & STATUS
# -----------------------------------------------------------------------------
OLD_FILES="/root/es_old_files/$DATE"
mkdir -p $OLD_FILES

# network status
echo "# ----- ip addr -----" >> $OLD_FILES/network.status
ip addr >> $OLD_FILES/network.status
echo >> $OLD_FILES/network.status
echo "# ----- ip route -----" >> $OLD_FILES/network.status
ip route >> $OLD_FILES/network.status

# nftables status
if [ "$(systemctl is-active nftables.service)" = "active" ]
then
	echo "# ----- nft list ruleset -----" >> $OLD_FILES/nftables.status
	nft list ruleset >> $OLD_FILES/nftables.status
fi

# process status
echo "# ----- ps auxfw -----" >> $OLD_FILES/ps.status
ps auxfw >> $OLD_FILES/ps.status

# Deb status
echo "# ----- dpkg -l -----" >> $OLD_FILES/dpkg.status
dpkg -l >> $OLD_FILES/dpkg.status

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# load modules before the possible kernel update
modprobe bridge

# upgrade
apt $APT_PROXY_OPTION -yd full-upgrade
apt $APT_PROXY_OPTION -y upgrade

# added packages
apt $APT_PROXY_OPTION -y install nftables
apt $APT_PROXY_OPTION -y install lxc debootstrap bridge-utils
apt $APT_PROXY_OPTION -y install dnsmasq
