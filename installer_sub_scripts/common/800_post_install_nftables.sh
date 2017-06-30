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
nft list ruleset >> /etc/nftables.conf
