#!/bin/bash

for mach in `lxc-ls -f | egrep 'RUNNING.*es-group' | cut -d ' ' -f1`
do
	echo
	echo "<<<" $mach ">>>"
	echo

	lxc-attach -n $mach -- /root/es_scripts/upgrade_debian.sh
done
