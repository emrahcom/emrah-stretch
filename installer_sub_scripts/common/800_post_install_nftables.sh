#!/bin/bash

# -----------------------------------------------------------------------------
# POST_INSTALL_NFTABLES.SH
# -----------------------------------------------------------------------------
set -e

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_POST_INSTALL" = true ] && exit

# -----------------------------------------------------------------------------
# NFTABLES
# -----------------------------------------------------------------------------
# recreate nftables.conf
cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

EOF

# save ruleset
# 
nft list ruleset -nn | \
    sed 's/^\(.* dnat to\).*"ES-MARK dont touch here"/\1 tcp dport map @port2ip : tcp dport map @port2port comment "ES-MARK dont touch here"/' \
    >> /etc/nftables.conf
