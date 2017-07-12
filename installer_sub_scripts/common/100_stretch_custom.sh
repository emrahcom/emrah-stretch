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
    "apt $APT_PROXY_OPTION update
     apt $APT_PROXY_OPTION -y dist-upgrade"

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "apt $APT_PROXY_OPTION -y install less tmux vim autojump
     apt $APT_PROXY_OPTION -y install curl dnsutils iputils-ping
     apt $APT_PROXY_OPTION -y install htop bmon bwm-ng
     apt $APT_PROXY_OPTION -y install rsync bzip2 man-db ack-grep"

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
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
