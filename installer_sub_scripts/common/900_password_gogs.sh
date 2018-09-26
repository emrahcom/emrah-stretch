#!/bin/bash

# -----------------------------------------------------------------------------
# PASSWORD_GOGS.SH
# -----------------------------------------------------------------------------
set -e
source $BASEDIR/$GIT_LOCAL_DIR/installer_sub_scripts/$INSTALLER/000_source
[ "$DONT_RUN_PASSWORD" = true ] && exit

if [ "$DONT_RUN_GOGS" != true ]
then
    echo "MariaDB Password: There is no password for gogs user."
    echo "                  It connects via UNIX socket."
fi
