#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#--------
#Settings
#--------

#Title shown for page - change for other communities
TITLE='Freifunk Lübeck Node Highscores'
#source of node data by ffmap-d3
JSONSRC='http://burgtor.ffhl/mesh/nodes.json'
#link to ffmap-d3 map
GRAPHLINK='http://burgtor.ffhl/mesh/nodes.html'

#password to start/stop updater thread over GET requests
PWD='hackme'
#update interval in minutes
INTERVAL=60

#score values
SC_OFFLINE=-100
SC_GATEWAY=100
SC_PERCLIENT=25
SC_PERVPN=10 #divided by quality
SC_PERMESH=50 #divided by quality

#fun option - penalty for Apple devices connected
PUNISHAPPLE=true
SC_PERAPPLE=-15

#hide following nodes from scores
BLACKLIST=['burgtor','holstentor','muehlentor']

