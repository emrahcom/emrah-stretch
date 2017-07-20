# -----------------------------------------------------------------------------
# COMPILER.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="es-compiler"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
DNS_RECORD=$(grep "address=/$MACH/" /etc/dnsmasq.d/es_hosts | head -n1)
IP=${DNS_RECORD##*/}
SSH_PORT="30$(printf %03d ${IP##*.})"
echo COMPILER="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# NFTABLES RULES
# -----------------------------------------------------------------------------
# public ssh
nft add element es-nat port2ip { $SSH_PORT : $IP }
nft add element es-nat port2port { $SSH_PORT : 22 }

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_COMPILER" = true ] && exit
cd $BASEDIR/$GIT_LOCAL_DIR/lxc/$MACH

echo
echo "-------------------------- $MACH --------------------------"

# -----------------------------------------------------------------------------
# REINSTALL_IF_EXISTS
# -----------------------------------------------------------------------------
EXISTS=$(lxc-info -n $MACH | egrep '^State' || true)
[ -n "$EXISTS" -a "$REINSTALL_COMPILER_IF_EXISTS" != true ] && exit

# -----------------------------------------------------------------------------
# CONTAINER SETUP
# -----------------------------------------------------------------------------
# remove the old container if exists
set +e
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-destroy -n $MACH
rm -rf /var/lib/lxc/$MACH
set -e

# create the new one
lxc-copy -n es-stretch -N $MACH -p /var/lib/lxc/

# shared directories
mkdir -p $SHARED
cp -arp $BASEDIR/$GIT_LOCAL_DIR/host/usr/local/es/deb $SHARED/
cp -arp $BASEDIR/$GIT_LOCAL_DIR/host/usr/local/es/share $SHARED/

# container config
rm -rf $ROOTFS/var/cache/apt/archives
mkdir -p $ROOTFS/var/cache/apt/archives
rm -rf $ROOTFS/usr/local/es/deb
mkdir -p $ROOTFS/usr/local/es/deb
rm -rf $ROOTFS/usr/local/es/share
mkdir -p $ROOTFS/usr/local/es/share
sed -i '/\/var\/cache\/apt\/archives/d' /var/lib/lxc/$MACH/config
sed -i '/lxc\.network\./d' /var/lib/lxc/$MACH/config
cat >> /var/lib/lxc/$MACH/config <<EOF

#lxc.start.auto = 1
lxc.start.order = 100
lxc.start.delay = 2
lxc.group = es-group
#lxc.group = onboot

lxc.mount.entry = /var/cache/apt/archives \
$ROOTFS/var/cache/apt/archives none bind 0 0
lxc.mount.entry = $SHARED/deb $ROOTFS/usr/local/es/deb none bind 0 0
lxc.mount.entry = $SHARED/share $ROOTFS/usr/local/es/share none bind 0 0

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $BRIDGE
lxc.network.name = $PUBLIC_INTERFACE
lxc.network.ipv4 = $IP/24
lxc.network.ipv4.gateway = auto
EOF

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- \
    zsh -c \
    "apt $APT_PROXY_OPTION update
     apt $APT_PROXY_OPTION -y full-upgrade"

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt $APT_PROXY_OPTION -y install dpkg-dev build-essential git
     apt $APT_PROXY_OPTION -y install fakeroot unzip"

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
