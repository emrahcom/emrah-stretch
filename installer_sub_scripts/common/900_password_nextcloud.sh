#!/bin/bash

# -----------------------------------------------------------------------------
# PASSWORD_NEXTCLOUD.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_PASSWORD" = true ] && exit

if [ "$DONT_RUN_NEXTCLOUD" != true ]
then
    echo "NextCloud User     : admin"
    echo "NextCloud Password : $ADMIN_PASSWORD"
fi
