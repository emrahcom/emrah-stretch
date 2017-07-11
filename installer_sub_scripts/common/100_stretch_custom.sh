# -----------------------------------------------------------------------------
# STRETCH_CUSTOM.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_STRETCH_CUSTOM" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
MACH="es-stretch"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
cd $BASEDIR/$GIT_LOCAL_DIR/lxc/$MACH

echo
echo "---------------------- $MACH CUSTOM -----------------------"

# start container
lxc-start -d -n $MACH
lxc-wait -n $MACH -s RUNNING

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- \
    zsh -c \
    'apt update
     apt dist-upgrade -y'

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    'apt install -y less tmux vim autojump
     apt install -y curl dnsutils iputils-ping
     apt install -y htop bmon bwm-ng
     apt install -y rsync bzip2 man-db ack-grep'

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# shell
lxc-attach -n $MACH -- chsh -s /bin/zsh root
cp root/.bashrc $ROOTFS/root/
cp root/.vimrc $ROOTFS/root/
cp root/.zshrc $ROOTFS/root/

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- poweroff
lxc-wait -n $MACH -s STOPPED
