#!/bin/bash

# -----------------------------------------------------------------------------
# SOURCE.SH
# -----------------------------------------------------------------------------
set -e
SOURCE="$BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source"

echo
echo "-------------------------- SOURCE -------------------------"

# -----------------------------------------------------------------------------
# SET GLOBAL VARIABLES
# -----------------------------------------------------------------------------
# Version
VERSION=$(git log --date=format:'%Y%m%d-%H%M' | egrep -i '^date:' | \
          head -n1 | awk '{print $2}')
echo "export VERSION=$VERSION" >> $SOURCE

# RAM capacity
RAM=$(free -m | grep Mem: | awk '{ print $2 }')
echo "export RAM=$RAM" >> $SOURCE
