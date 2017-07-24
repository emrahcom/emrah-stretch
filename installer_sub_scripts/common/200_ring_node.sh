# -----------------------------------------------------------------------------
# RING_NODE.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="es-ring-node"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
DNS_RECORD=$(grep "address=/$MACH/" /etc/dnsmasq.d/es_hosts | head -n1)
IP=${DNS_RECORD##*/}
SSH_PORT="30$(printf %03d ${IP##*.})"
echo LIVESTREAM_ORIGIN="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# NFTABLES RULES
# -----------------------------------------------------------------------------
# public ssh
nft add element es-nat tcp2ip { $SSH_PORT : $IP }
nft add element es-nat tcp2port { $SSH_PORT : 22 }
# public opendht node
nft add element es-nat udp2ip { 4222 : $IP }
nft add element es-nat udp2port { 4222 : 4222 }

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_RING_NODE" = true ] && exit
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
set -e

# create the new one
lxc-copy -n es-stretch -N $MACH -p /var/lib/lxc/

# container config
rm -rf $ROOTFS/var/cache/apt/archives
mkdir -p $ROOTFS/var/cache/apt/archives
rm -rf $ROOTFS/usr/local/es/share
mkdir -p $ROOTFS/usr/local/es/share
sed -i '/\/var\/cache\/apt\/archives/d' /var/lib/lxc/$MACH/config
sed -i '/lxc\.network\./d' /var/lib/lxc/$MACH/config
cat >> /var/lib/lxc/$MACH/config <<EOF

lxc.start.auto = 1
lxc.start.order = 600
lxc.start.delay = 2
lxc.group = es-group
lxc.group = onboot

lxc.mount.entry = /var/cache/apt/archives \
$ROOTFS/var/cache/apt/archives none bind 0 0
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
     apt $APT_PROXY_OPTION -y install make cmake
     apt $APT_PROXY_OPTION -y install libargon2-0
     apt $APT_PROXY_OPTION -y install python3-setuptools cython3"

# opendht
lxc-attach -n $MACH -- \
    zsh -c \
    "ln -s libgnutls.so.30 /usr/lib/x86_64-linux-gnu/libgnutls.so

     cd /usr/local/es/share/es-ring-node/source/opendht/build
     make install"

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
cp etc/dhtnode.conf $ROOTFS/etc/

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- systemctl daemon-reload
lxc-attach -n $MACH -- systemctl enable dhtnode.service

lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
