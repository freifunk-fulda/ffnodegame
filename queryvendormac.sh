#!/bin/sh
#get current MAC address listing and filter for a vendor
wget -q -O- http://standards.ieee.org/develop/regauth/oui/oui.txt | grep -i $1 | grep "(hex)" | awk '{print$1}' | sed 's/-/:/g'
