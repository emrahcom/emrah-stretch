#!/bin/bash

# -----------------------------------------------------------------------------
# NETWORK.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
# public interface
DEFAULT_ROUTE=$(ip route | egrep '^default ' | head -n1)
PUBLIC_INTERFACE=${DEFAULT_ROUTE##*dev }
PUBLIC_INTERFACE=${PUBLIC_INTERFACE/% */}
echo PUBLIC_INTERFACE="$PUBLIC_INTERFACE" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# IP address
DNS_RECORD=$(grep 'address=/host/' ../../host/etc/dnsmasq.d/es_hosts | \
    head -n1)
IP=${DNS_RECORD##*/}
echo HOST="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_NETWORK_INIT" = true ] && exit
cd $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER

echo
echo "------------------------- NETWORK --------------------------"

# -----------------------------------------------------------------------------
# BACKUP & STATUS
# -----------------------------------------------------------------------------
OLD_FILES="/root/es_old_files/$DATE"
mkdir -p $OLD_FILES

# backup the files which will be changed
[ -f /etc/nftables.conf ] && cp /etc/nftables.conf $OLD_FILES/
[ -f /etc/network/interfaces ] && cp /etc/network/interfaces $OLD_FILES/
[ -f /etc/dnsmasq.d/es_hosts ] && \
    cp /etc/dnsmasq.d/es_hosts $OLD_FILES/

# network status
echo "# ----- ip addr -----" >> $OLD_FILES/network.status
ip addr >> $OLD_FILES/network.status
echo >> $OLD_FILES/network.status
echo "# ----- ip route -----" >> $OLD_FILES/network.status
ip route >> $OLD_FILES/network.status

# nftables status
if [ "$(systemctl is-active nftables.service)" = "active" ]
then
	echo "# ----- nft list ruleset -----" >> $OLD_FILES/nftables.status
	nft list ruleset >> $OLD_FILES/nftables.status
fi

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
apt $APT_PROXY_OPTION -y install nftables

# -----------------------------------------------------------------------------
# NETWORK CONFIG
# -----------------------------------------------------------------------------
# changed/added system files
cp ../../host/etc/dnsmasq.d/es_hosts /etc/dnsmasq.d/

# /etc/network/interfaces
[ -z "$(egrep '^source-directory\s*interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source-directory\s*/etc/network/interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/\*' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/\*' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/es_bridge' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/es_bridge' /etc/network/interfaces || true)" ] && \
echo -e "\nsource /etc/network/interfaces.d/es_bridge" >> /etc/network/interfaces

# IP forwarding
cp ../../host/etc/sysctl.d/es_ip_forward.conf /etc/sysctl.d/
sysctl -p /etc/sysctl.d/es_ip_forward.conf

# -----------------------------------------------------------------------------
# BRIDGE CONFIG
# -----------------------------------------------------------------------------
# private bridge interface for the containers
BR_EXISTS=$(brctl show | egrep "^$BRIDGE\s" || true)
[ -z "$BR_EXISTS" ] && brctl addbr $BRIDGE
ip link set $BRIDGE up
IP_EXISTS=$(ip a show dev $BRIDGE | egrep "inet $IP/24" || true)
[ -z "$IP_EXISTS" ] && ip addr add dev $BRIDGE $IP/24 brd 172.22.22.255

cp ../../host/etc/network/interfaces.d/es_bridge /etc/network/interfaces.d/
sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/network/interfaces.d/es_bridge
cp ../../host/etc/dnsmasq.d/es_interface /etc/dnsmasq.d/
sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/dnsmasq.d/es_interface

# -----------------------------------------------------------------------------
# NFTABLES
# -----------------------------------------------------------------------------
TABLE_EXISTS=$(nft list ruleset | grep "table inet es-filter" || true)
[ -n "$TABLE_EXISTS" ] && nft delete table inet es-filter

nft add table inet es-filter
nft add chain inet es-filter \
    input { type filter hook input priority 0 \; }
nft add chain inet es-filter \
    forward { type filter hook forward priority 0 \; }
nft add chain inet es-filter \
    output { type filter hook output priority 0 \; }
# drop packets coming from the public interface to the private network
nft add rule inet es-filter output \
    iif $PUBLIC_INTERFACE ip daddr 172.22.22.0/24 drop

TABLE_EXISTS=$(nft list ruleset | grep "table ip es-nat" || true)
[ -n "$TABLE_EXISTS" ] && nft delete table ip es-nat

nft add table ip es-nat
nft add chain ip es-nat prerouting \
    { type nat hook prerouting priority 0 \; }
nft add chain ip es-nat postrouting \
    { type nat hook postrouting priority 100 \; }
# masquerade packets coming from the private network
nft add rule ip es-nat postrouting \
    ip saddr 172.22.22.0/24 masquerade

# dnat tcp maps
nft add map ip es-nat tcp2ip \
    { type inet_service : ipv4_addr \; }
nft add map ip es-nat tcp2port \
    { type inet_service : inet_service \; }
nft add rule ip es-nat prerouting \
    iif $PUBLIC_INTERFACE dnat \
    tcp dport map @tcp2ip : tcp dport map @tcp2port \
    comment \"ES-MARK-TCP dont touch here\"

# dnat udp maps
nft add map ip es-nat udp2ip \
    { type inet_service : ipv4_addr \; }
nft add map ip es-nat udp2port \
    { type inet_service : inet_service \; }
nft add rule ip es-nat prerouting \
    iif $PUBLIC_INTERFACE dnat \
    udp dport map @udp2ip : udp dport map @udp2port \
    comment \"ES-MARK-UDP dont touch here\"

# -----------------------------------------------------------------------------
# NETWORK RELATED SERVICES
# -----------------------------------------------------------------------------
# dnsmasq
systemctl stop dnsmasq.service
systemctl start dnsmasq.service

# nftables
systemctl enable nftables.service

# -----------------------------------------------------------------------------
# STATUS
# -----------------------------------------------------------------------------
ip addr
