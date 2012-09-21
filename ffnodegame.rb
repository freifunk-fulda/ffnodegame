#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#TODO: eval bonus/penalty points added by hand in bonus.json
#      add other automatic bonus points - eval some infos from mac address?

require 'net/http'
require 'json'
require 'sinatra'

require './settings'
require './generator'
require './updater'

set :port, PORT

#run updater thread in background on startup
Updater.start

#sinatra routes
get '/start' do
  if params['pw'] == PWD
    val = Updater.start
    val ? 'Updater started!' : 'Already running!'
  else
    'Wrong password!'
  end
end

get '/stop' do
  if params['pw'] == PWD
    Updater.stop
    'Requesting thread to die!'
  else
    'Wrong password!'
  end
end

get '/status' do
  "Updater thread is#{Updater.running? ? ' ' : ' NOT '}running!"
end

#----

get '/update' do
  if params['pw'] == PWD
    Generator.execute
    'Scores updated!'
  else
    'Wrong password!'
  end
end

get '/reset' do
  if params['pw'] == PWD
    File.delete 'public/scores.json'
    Generator.execute
    'Scores reset!'
  else
    'Wrong password!'
  end
end

get '/' do
  begin
    @lastupdate = File.mtime 'public/scores.json'
    @scores = JSON.parse File.readlines('public/scores.json').join
    erb :index
  rescue
    "Error: no scores.json file found!"
  end
end

