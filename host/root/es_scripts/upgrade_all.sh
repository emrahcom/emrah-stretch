#!/bin/bash

echo
echo "<<< HOST >>>"
echo
/root/es_scripts/upgrade_debian.sh

echo
echo "<<< CONTAINERS >>>"
echo
/root/es_scripts/upgrade_container.sh
