#!/bin/bash

# -----------------------------------------------------------------------------
# PASSWORD_NEXTCLOUD.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_PASSWORD" = true ] && exit

if [ "$DONT_RUN_NEXTCLOUD" != true ]
then
    echo "MySQL Password: There is no password for local access."
    echo "                Please, leave blank"
fi
