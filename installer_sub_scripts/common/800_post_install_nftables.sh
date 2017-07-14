#!/bin/bash

# -----------------------------------------------------------------------------
# POST_INSTALL_NFTABLES.SH
# -----------------------------------------------------------------------------
set -e
[ "$DONT_RUN_POST_INSTALL" = true ] && exit

# recreate nftables.conf
cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

EOF

# save ruleset
# 
nft list ruleset -nn | \
    sed 's/^\(.* dnat to\).*"FIXME missing port2ip"/\1 tcp dport map @port2ip : tcp dport map @port2port comment "FIXME missing port2ip"/' \
    >> /etc/nftables.conf
