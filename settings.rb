#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#--------
#Settings
#--------
#

#source path of node data
JSONSRC='http://map.fffd/nodes.html'

#password for commands over GET requests
PWD='hackme'

#score values
SC_OFFLINE=-100
SC_GATEWAY=0
SC_PERCLIENT=25
SC_PERVPN=10 #divided by quality
SC_PERMESH=50 #divided by quality

#fun option - penalty for Apple devices connected
PUNISHAPPLE=false
SC_PERAPPLE=-15

#----

#hide following nodes from scores
BLACKLIST=['gw01', 'gw02', 'fffd-srv1', 'fffd-srv2', 'fffd-nms']

#----

#enable logging
LOG=true
