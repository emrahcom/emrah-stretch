# -----------------------------------------------------------------------------
# NEXTCLOUD.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="es-nextcloud"
ROOTFS="/var/lib/lxc/$MACH/rootfs"
DNS_RECORD=$(grep "address=/$MACH/" /etc/dnsmasq.d/es_hosts | head -n1)
IP=${DNS_RECORD##*/}
SSH_PORT="30$(printf %03d ${IP##*.})"
echo NEXTCLOUD="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# NFTABLES RULES
# -----------------------------------------------------------------------------
# public ssh
nft add element es-nat tcp2ip { $SSH_PORT : $IP }
nft add element es-nat tcp2port { $SSH_PORT : 22 }
# public http
nft add element es-nat tcp2ip { 80 : $IP }
nft add element es-nat tcp2port { 80 : 80 }
# public https
nft add element es-nat tcp2ip { 443 : $IP }
nft add element es-nat tcp2port { 443 : 443 }

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_NEXTCLOUD" = true ] && exit
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
     debconf-set-selections <<< \
         'mysql-server mysql-server/root_password password'
     debconf-set-selections <<< \
         'mysql-server mysql-server/root_password_again password'
     apt $APT_PROXY_OPTION -y install mariadb-server"

lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt $APT_PROXY_OPTION -y install ssl-cert ca-certificates certbot
     apt $APT_PROXY_OPTION -y install apache2
     apt $APT_PROXY_OPTION -y --install-recommends install \
         php libapache2-mod-php php-gd php-json php-mysql php-curl \
	 php-mbstring php-intl php-mcrypt php-imagick php-xml php-zip"

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# NEXTCLOUD
# -----------------------------------------------------------------------------
DATABASE_PASSWORD=$(echo -n $RANDOM$RANDOM$RANDOM | sha256sum | cut -c 1-20)
ADMIN_PASSWORD=$(echo -n $RANDOM$RANDOM$RANDOM | sha256sum | cut -c 1-20)
echo "export ADMIN_PASSWORD=$ADMIN_PASSWORD" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

lxc-attach -n $MACH -- mysql <<EOF
CREATE DATABASE nextcloud DEFAULT CHARACTER SET utf8mb4;
CREATE USER nextcloud@localhost IDENTIFIED BY '$DATABASE_PASSWORD';
GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;
EOF

lxc-attach -n $MACH -- \
    zsh -c \
    "wget https://download.nextcloud.com/server/releases/latest.tar.bz2
     tar -jxf latest.tar.bz2 -C /var/www/
     chown -R www-data:www-data /var/www/nextcloud"

lxc-attach -n $MACH -- \
    zsh -c \
    "cd /var/www/nextcloud
     php occ  maintenance:install \
         --database 'mysql' --database-name 'nextcloud' \
         --database-user 'nextcloud' --database-pass '$DATABASE_PASSWORD' \
         --admin-user 'admin' --admin-pass '$ADMIN_PASSWORD'
     chown -R www-data:www-data /var/www/nextcloud"

# -----------------------------------------------------------------------------
# SSL
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- \
    zsh -c \
    "cp -ap /etc/ssl/certs/{ssl-cert-snakeoil.pem,ssl-es.pem}
     cp -ap /etc/ssl/private/{ssl-cert-snakeoil.key,ssl-es.key}"

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-attach -n $MACH -- systemctl restart mariadb.service
lxc-attach -n $MACH -- systemctl restart nginx.service

lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
