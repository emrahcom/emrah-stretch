# -----------------------------------------------------------------------------
# LIVESTREAM_ORIGIN.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="es-livestream-origin"
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
# rtmp push
nft add element es-nat tcp2ip { 1935 : $IP }
nft add element es-nat tcp2port { 1935 : 1935 }
# mpeg-ts push
nft add element es-nat tcp2ip { 8000 : $IP }
nft add element es-nat tcp2port { 8000 : 80 }

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_LIVESTREAM_ORIGIN" = true ] && exit
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

# shared directories
mkdir -p $SHARED
cp -arp $BASEDIR/$GIT_LOCAL_DIR/host/usr/local/es/livestream $SHARED/

# container config
rm -rf $ROOTFS/var/cache/apt/archives
mkdir -p $ROOTFS/var/cache/apt/archives
rm -rf $ROOTFS/usr/local/es/deb
mkdir -p $ROOTFS/usr/local/es/deb
rm -rf $ROOTFS/usr/local/es/livestream
mkdir -p $ROOTFS/usr/local/es/livestream
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
lxc.mount.entry = $SHARED/deb $ROOTFS/usr/local/es/deb none bind 0 0
lxc.mount.entry = $SHARED/livestream \
$ROOTFS/usr/local/es/livestream none bind 0 0

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
     apt $APT_PROXY_OPTION -y full-upgrade"

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt $APT_PROXY_OPTION -y install ffmpeg
     apt $APT_PROXY_OPTION -y install libgd3 libluajit-5.1-2 libxslt1.1 \
         libhiredis0.13
     dpkg -i /usr/local/es/deb/es-livestream-origin/nginx-common_*.deb
     dpkg -i /usr/local/es/deb/es-livestream-origin/libnginx-mod-*.deb
     dpkg -i /usr/local/es/deb/es-livestream-origin/nginx-extras_*.deb
     dpkg -i /usr/local/es/deb/es-livestream-origin/nginx-doc_*.deb
     apt-mark hold nginx-common nginx-extras nginx-doc

     mkdir -p /usr/local/es/livestream/stat/
     gunzip -c /usr/share/doc/nginx-doc/examples/rtmp_stat.xsl.gz > \
         /usr/local/es/livestream/stat/rtmp_stat.xsl
     chown www-data: /usr/local/es/livestream/stat -R"
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt $APT_PROXY_OPTION -y install uwsgi uwsgi-plugin-python3
     apt $APT_PROXY_OPTION --install-recommends -y install python3-pip
     pip3 install --upgrade setuptools
     pip3 install mydaemon
     pip3 install flask"

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
rm -rf $ROOTFS/var/www/livestream_cloner
mkdir -p $ROOTFS/var/www/livestream_cloner
rsync -aChu var/www/livestream_cloner/ $ROOTFS/var/www/livestream_cloner/
chown www-data:www-data $ROOTFS/var/www/livestream_cloner -R

cp etc/uwsgi/apps-available/livestream_cloner.ini \
    $ROOTFS/etc/uwsgi/apps-available/
ln -s ../apps-available/livestream_cloner.ini $ROOTFS/etc/uwsgi/apps-enabled/

cp etc/nginx/nginx.conf $ROOTFS/etc/nginx/
cp etc/nginx/access_list_http.conf $ROOTFS/etc/nginx/
cp etc/nginx/access_list_rtmp.conf $ROOTFS/etc/nginx/
cp etc/nginx/conf.d/custom.conf $ROOTFS/etc/nginx/conf.d/
cp etc/nginx/sites-available/default $ROOTFS/etc/nginx/sites-available/

cp -arp root/es_scripts/ $ROOTFS/root/
chmod u+x $ROOTFS/root/es_scripts/*.sh
cp etc/cron.d/es_livestream_cleanup $ROOTFS/etc/cron.d/

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- systemctl restart uwsgi
lxc-attach -n $MACH -- systemctl reload nginx

lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
