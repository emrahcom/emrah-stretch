#!/bin/bash

# -----------------------------------------------------------------------------
# HOST.SH
# -----------------------------------------------------------------------------
set -e
[ "$DONT_RUN_HOST" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
cd $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER

echo
echo "-------------------------- HOST ---------------------------"

# -----------------------------------------------------------------------------
# BACKUP & STATUS
# -----------------------------------------------------------------------------
OLD_FILES="/root/es_old_files/$DATE"
mkdir -p $OLD_FILES

# backup the files which will be changed
[ -f /etc/network/interfaces ] && cp /etc/network/interfaces $OLD_FILES/

# network status
echo "# ----- ip addr -----" >> $OLD_FILES/network.status
ip addr >> $OLD_FILES/network.status
echo >> $OLD_FILES/network.status
echo "# ----- ip route -----" >> $OLD_FILES/network.status
ip route >> $OLD_FILES/network.status

# nftables status
if [ -n "`command -v nft`" ]
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
# repo update & upgrade
apt update
apt -dy dist-upgrade
apt -y upgrade

# added packages
apt install -y nftables
apt install -y zsh tmux vim
apt install -y cron
apt install -y bridge-utils
apt install -y lxc debootstrap
apt install -y htop iotop bmon bwm-ng
apt install -y iputils-ping fping wget curl whois dnsutils
apt install -y bzip2 rsync ack-grep
apt install -y openntpd dnsmasq

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# changed/added system files
cp ../../host/etc/cron.d/es_update /etc/cron.d/
cp ../../host/etc/sysctl.d/es_ip_forward.conf /etc/sysctl.d/
cp ../../host/etc/sysctl.d/es_max_user_instances.conf /etc/sysctl.d/
cp ../../host/etc/network/interfaces.d/es_bridge /etc/network/interfaces.d/
cp ../../host/etc/dnsmasq.d/es_interface /etc/dnsmasq.d/
cp ../../host/etc/dnsmasq.d/es_hosts /etc/dnsmasq.d/

sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/network/interfaces.d/es_bridge
sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/dnsmasq.d/es_interface

[ -z "$(egrep '^source-directory\s*interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source-directory\s*/etc/network/interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/\*' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/\*' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/es_bridge' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/es_bridge' /etc/network/interfaces || true)" ] && \
echo -e "\nsource /etc/network/interfaces.d/es_bridge" >> /etc/network/interfaces

# sysctl.d
sysctl -p

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# added directories
mkdir -p /root/es_scripts

# changed/added files
cp ../../host/root/es_scripts/update_debian.sh /root/es_scripts/
cp ../../host/root/es_scripts/update_container.sh /root/es_scripts/
cp ../../host/root/es_scripts/upgrade_debian.sh /root/es_scripts/
cp ../../host/root/es_scripts/upgrade_container.sh /root/es_scripts/
cp ../../host/root/es_scripts/upgrade_all.sh /root/es_scripts/

# file permissons
chmod u+x /root/es_scripts/update_debian.sh
chmod u+x /root/es_scripts/update_container.sh
chmod u+x /root/es_scripts/upgrade_debian.sh
chmod u+x /root/es_scripts/upgrade_container.sh
chmod u+x /root/es_scripts/upgrade_all.sh
