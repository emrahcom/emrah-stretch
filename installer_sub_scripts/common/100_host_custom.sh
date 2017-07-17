#!/bin/bash

# -----------------------------------------------------------------------------
# HOST.SH
# -----------------------------------------------------------------------------
set -e
[ "$DONT_RUN_HOST_CUSTOM" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
cd $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER

echo
echo "---------------------- HOST CUSTOM ------------------------"

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# repo update & upgrade
apt $APT_PROXY_OPTION update
apt $APT_PROXY_OPTION -yd full-upgrade
apt $APT_PROXY_OPTION -y upgrade

# added packages
apt $APT_PROXY_OPTION -y install cron
apt $APT_PROXY_OPTION -y install zsh tmux vim
apt $APT_PROXY_OPTION -y install htop iotop bmon bwm-ng
apt $APT_PROXY_OPTION -y install iputils-ping fping wget curl whois dnsutils
apt $APT_PROXY_OPTION -y install bzip2 rsync ack-grep

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# changed/added system files
cp ../../host/etc/cron.d/es_update /etc/cron.d/

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
