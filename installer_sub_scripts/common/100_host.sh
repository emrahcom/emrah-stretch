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

# process status
echo "# ----- ps auxfw -----" >> $OLD_FILES/ps.status
ps auxfw >> $OLD_FILES/ps.status

# Deb status
echo "# ----- dpkg -l -----" >> $OLD_FILES/dpkg.status
dpkg -l >> $OLD_FILES/dpkg.status

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# load the bridge module before the possible kernel update
[ -n "$(command -v modprobe)" ] && modprobe bridge

# upgrade
apt $APT_PROXY_OPTION -yd full-upgrade
apt $APT_PROXY_OPTION -y upgrade

# added packages
apt $APT_PROXY_OPTION -y install lxc debootstrap bridge-utils
apt $APT_PROXY_OPTION -y install dnsmasq
