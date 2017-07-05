# -----------------------------------------------------------------------------
# STRETCH.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_STRETCH" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
MACH="es-stretch"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
DNS_RECORD=$(grep "address=/$MACH/" /etc/dnsmasq.d/es_hosts | head -n1)
IP=${DNS_RECORD##*/}
SSH_PORT="30${IP##*.}"
echo STRETCH="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
cd $BASEDIR/$GIT_LOCAL_DIR/lxc/$MACH

echo
echo "-------------------------- $MACH --------------------------"

# -----------------------------------------------------------------------------
# CONTAINER SETUP
# -----------------------------------------------------------------------------
# remove the old container if exists
set +e
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-destroy -n $MACH
rm -rf /var/lib/lxc/$MACH
sleep 1
set -e

# create the new one
lxc-create -n $MACH -t debian -P /var/lib/lxc/ -- -r stretch

# container config
rm -rf $ROOTFS/var/cache/apt/archives
mkdir -p $ROOTFS/var/cache/apt/archives
sed -i '/lxc\.network\./d' /var/lib/lxc/$MACH/config
cat >> /var/lib/lxc/$MACH/config <<EOF

lxc.mount.entry = /var/cache/apt/archives \
$ROOTFS/var/cache/apt/archives none bind 0 0

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $BRIDGE
lxc.network.name = $PUBLIC_INTERFACE
lxc.network.ipv4 = $IP/24
lxc.network.ipv4.gateway = auto
EOF

# changed/added system files
echo nameserver $HOST > $ROOTFS/etc/resolv.conf
cp etc/network/interfaces $ROOTFS/etc/network/
cp etc/apt/sources.list $ROOTFS/etc/apt/
cp etc/apt/apt.conf.d/80recommends $ROOTFS/etc/apt/apt.conf.d/

# start container
lxc-start -d -n $MACH
lxc-wait -n $MACH -s RUNNING

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- apt update
lxc-attach -n $MACH -- apt dist-upgrade -y

# packages
lxc-attach -n $MACH -- apt install -y openssh-server openssh-client
lxc-attach -n $MACH -- apt install -y cron logrotate
lxc-attach -n $MACH -- apt install -y dbus libpam-systemd

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# ssh
if [ -f /root/.ssh/authorized_keys ]
then
    mkdir $ROOTFS/root/.ssh
    cp /root/.ssh/authorized_keys $ROOTFS/root/.ssh/
    chmod 700 $ROOTFS/root/.ssh
    chmod 600 $ROOTFS/root/.ssh/authorized_keys
fi

# es_scripts
mkdir $ROOTFS/root/es_scripts
cp root/es_scripts/update_debian.sh $ROOTFS/root/es_scripts/
cp root/es_scripts/upgrade_debian.sh $ROOTFS/root/es_scripts/
chmod 744 $ROOTFS/root/es_scripts/update_debian.sh
chmod 744 $ROOTFS/root/es_scripts/upgrade_debian.sh

# -----------------------------------------------------------------------------
# NFTABLES RULES
# -----------------------------------------------------------------------------
# public ssh
nft add element es-nat port2ip { $SSH_PORT : $IP }
nft add element es-nat port2port { $SSH_PORT : 22 }

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- poweroff
lxc-wait -n $MACH -s STOPPED
