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
    sed 's/^\(\s*\).*"FIXME missing port2ip"/\1dnat to tcp dport map @port2ip : tcp dport map @port2port comment "FIXME missing port2ip"/' \
    >> /etc/nftables.conf
