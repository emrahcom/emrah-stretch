#!/bin/bash

# -----------------------------------------------------------------------------
# NETWORK.SH
# -----------------------------------------------------------------------------
set -e
[ "$DONT_RUN_NETWORK" = true ] && exit

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
echo
echo "------------------------- NETWORK --------------------------"

# -----------------------------------------------------------------------------
# NETWORK CONFIG
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

# private bridge interface for the containers
BR_EXISTS=$(brctl show | egrep "^$BRIDGE\s" || true)
[ -z "$BR_EXISTS" ] && brctl addbr $BRIDGE
IP_EXISTS=$(ip a show dev $BRIDGE | egrep "inet $IP/24" || true)
[ -z "$IP_EXISTS" ] && ip addr add dev $BRIDGE $IP/24

# IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# -----------------------------------------------------------------------------
# NFTABLES
# -----------------------------------------------------------------------------
TABLE_EXISTS=$(nft list ruleset | grep "table inet es-host-filter" || true)
[ -n "$TABLE_EXISTS" ] && nft delete table inet es-host-filter

nft add table inet es-host-filter
nft add chain inet es-host-filter \
    input { type filter hook input priority 0 \; }
nft add chain inet es-host-filter \
    forward { type filter hook forward priority 0 \; }
nft add chain inet es-host-filter \
    output { type filter hook output priority 0 \; }
# drop packets coming from the public interface to the private network
nft add rule inet es-host-filter output \
    iif $PUBLIC_INTERFACE ip daddr 172.22.22.0/24 drop

TABLE_EXISTS=$(nft list ruleset | grep "table ip es-host-nat" || true)
[ -n "$TABLE_EXISTS" ] && nft delete table ip es-host-nat

nft add table ip es-host-nat
nft add chain ip es-host-nat postrouting \
    { type nat hook postrouting priority 100 \; }
# masquerade packets coming from the private network
nft add rule ip es-host-nat postrouting \
    ip saddr 172.22.22.0/24 masquerade

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
