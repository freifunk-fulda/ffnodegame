#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#--------
#Settings
#--------

#port for server
PORT=1337
#source of node data by ffmap-d3
JSONSRC='http://burgtor.ffhl/mesh/nodes.json'
#Title shown for page - change for other communities
TITLE='Freifunk Lübeck Node Highscores'
#password to start/stop updater thread over GET requests
PWD='hackme'
#update interval in minutes
INTERVAL=5

#score values
SC_OFFLINE=-100
SC_GATEWAY=100
SC_PERCLIENT=25
SC_PERVPN=10 #divided by quality
SC_PERMESH=50 #divided by quality

#extra output
DEBUG=true
