# -----------------------------------------------------------------------------
# PRE_RING_NODE.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="es-compiler"
ROOTFS="/var/lib/lxc/$MACH/rootfs"

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_PRE_RING_NODE" = true ] && exit
cd $BASEDIR/$GIT_LOCAL_DIR/lxc/$MACH

echo
echo "------------------ PRE RING NODE ------------------"

# -----------------------------------------------------------------------------
# CONTAINER SETUP
# -----------------------------------------------------------------------------
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
     apt $APT_PROXY_OPTION -y install libncurses5-dev libreadline-dev \
         nettle-dev libgnutls28-dev
     apt $APT_PROXY_OPTION -y install libargon2-0-dev libmsgpack-dev
     apt $APT_PROXY_OPTION -y install cython3 python3-dev python3-setuptools"

# opendht
REPO="https://github.com/savoirfairelinux/opendht.git"
lxc-attach -n $MACH -- \
    zsh -c \
    "mkdir -p /root/source
     cd /root/source
     rm -rf opendht
     git clone $REPO
     cd opendht

     mkdir build
     cd build
     cmake .. -DOPENDHT_PYTHON=ON -DOPENDHT_SYSTEMD=ON \
         -DCMAKE_INSTALL_PREFIX=/usr
     make -j4
     cd ..
     
     rm -rf  /usr/local/es/share/opendht-build
     mv build /usr/local/es/share/opendht-build"

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
