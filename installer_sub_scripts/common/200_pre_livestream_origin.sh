# -----------------------------------------------------------------------------
# PRE_LIVESTREAM_ORIGIN.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_PRE_LIVESTREAM_ORIGIN" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
MACH="es-compiler"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
cd $BASEDIR/$GIT_LOCAL_DIR/lxc/$MACH

echo
echo "------------------ PRE LIVESTREAM ORIGIN ------------------"

# -----------------------------------------------------------------------------
# CONTAINER SETUP
# -----------------------------------------------------------------------------
# start container
lxc-start -d -n $MACH
lxc-wait -n $MACH -s RUNNING

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# multimedia repo
cp etc/apt/sources.list.d/multimedia.list $ROOTFS/etc/apt/sources.list.d/
lxc-attach -n $MACH -- \
    zsh -c \
    'apt update -oAcquire::AllowInsecureRepositories=true
     apt install -y --allow-unauthenticated deb-multimedia-keyring'

# update
lxc-attach -n $MACH -- \
    zsh -c \
    'apt update
     apt dist-upgrade -y'

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    'export DEBIAN_FRONTEND=noninteractive
     apt install -y ffmpeg
     apt build-dep -y nginx'

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- poweroff
lxc-wait -n $MACH -s STOPPED
