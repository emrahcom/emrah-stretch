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
    "apt $APT_PROXY_OPTION -oAcquire::AllowInsecureRepositories=true update
     apt $APT_PROXY_OPTION --allow-unauthenticated -y install \
         deb-multimedia-keyring"

# update
lxc-attach -n $MACH -- \
    zsh -c \
    "apt $APT_PROXY_OPTION update
     apt $APT_PROXY_OPTION -y dist-upgrade"

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt $APT_PROXY_OPTION -y install ffmpeg
     apt $APT_PROXY_OPTION -y build-dep nginx"

# nginx RTMP & MPEG-TS modules
MPEGTS="https://github.com/arut/nginx-ts-module/archive/master.zip"
RTMP="https://github.com/arut/nginx-rtmp-module/archive/master.zip"
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     mkdir -p /root/source
     cd /root/source
     setopt +o nomatch
     rm -rf nginx_* nginx-* libnginx-mod-*
     apt $APT_PROXY_OPTION source nginx

     wget $MPEGTS -O mpegts.zip
     unzip mpegts.zip
     
     wget $RTMP -O rtmp.zip
     unzip rtmp.zip"

lxc-attach -n $MACH -- \
    zsh -c \
    'cd /root/source
     NGINX_VERSION=$(ls nginx-[1-9].* -d)
     mv nginx-ts-module-master $NGINX_VERSION/debian/modules/nginx-ts-module
     mv nginx-rtmp-module-master \
         $NGINX_VERSION/debian/modules/nginx-rtmp-module
     sed -i "/--add-dynamic-module=.*headers-more-nginx-module/i \
         \\\\t\t\t--add-module=\$(MODULESDIR)\/nginx-ts-module \\\\" \
	 $NGINX_VERSION/debian/rules
     sed -i "/--add-dynamic-module=.*headers-more-nginx-module/i \
         \\\\t\t\t--add-module=\$(MODULESDIR)\/nginx-rtmp-module \\\\" \
	 $NGINX_VERSION/debian/rules
     cd $NGINX_VERSION
     cp debian/modules/nginx-rtmp-module/stat.xsl \
         debian/help/examples/rtmp_stat.xsl
     dpkg-buildpackage -rfakeroot -uc -b

     cd ..
     mkdir -p /usr/local/es/deb/livestream-origin
     rm -f /usr/local/es/deb/livestream-origin/libnginx-*.deb
     rm -f /usr/local/es/deb/livestream-origin/nginx-*.deb
     mv libnginx-*.deb nginx-*.deb /usr/local/es/deb/livestream-origin/'

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
