#!/bin/bash

# -----------------------------------------------------------------------------
# POST_INSTALL_NFTABLES.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source

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
    sed 's/^\(.* dnat to\).*"\(ES-MARK-TCP dont touch here\)"/\1 tcp dport map @tcp2ip : tcp dport map @tcp2port comment "\2"/' | \
    sed 's/^\(.* dnat to\).*"\(ES-MARK-UDP dont touch here\)"/\1 udp dport map @udp2ip : udp dport map @udp2port comment "\2"/' \
    >> /etc/nftables.conf
