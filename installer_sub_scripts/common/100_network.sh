#!/bin/bash

# -----------------------------------------------------------------------------
# NETWORK.SH
# -----------------------------------------------------------------------------
set -e

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
DNS_RECORD=$(grep 'address=/host/' /etc/dnsmasq.d/es_hosts | head -n1)
IP=${DNS_RECORD##*/}
echo HOST="$IP" >> \
    $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_NETWORK_INIT" = true ] && exit

echo
echo "------------------------- NETWORK --------------------------"

# -----------------------------------------------------------------------------
# NETWORK CONFIG
# -----------------------------------------------------------------------------
# private bridge interface for the containers
BR_EXISTS=$(brctl show | egrep "^$BRIDGE\s" || true)
[ -z "$BR_EXISTS" ] && brctl addbr $BRIDGE
ip link set $BRIDGE up
IP_EXISTS=$(ip a show dev $BRIDGE | egrep "inet $IP/24" || true)
[ -z "$IP_EXISTS" ] && ip addr add dev $BRIDGE $IP/24 brd 172.22.22.255

# IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

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
