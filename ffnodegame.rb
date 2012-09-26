#!/usr/bin/env ruby
# encoding: UTF-8
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

#TODO: value redundant meshing links less (or root function-style?)

require 'json'
require 'sinatra'

require './settings'
require './generator'
require './updater'

log "---- APPLICATION STARTING ----"

#run updater thread in background on startup
Updater.start if STARTUPDATER

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
    log 'Viewed by: '+request.ip

    @days = params.include?('days') ? params['days'].to_i : 1
    @days = 1 if @days <= 0
    @offset = params.include?('offset') ? params['offset'].to_i : 0
    @offset = 0 if @offset < 0

    @lastupdate = Generator.last_update
    @scores = Generator.generate @days, @offset

    erb :index
  rescue
    "An error occured, no scores.json file found or invalid parameter value!"
  end
end

helpers do
  def scores_for(days, offset)
    if days == 1
      return 'heute' if offset == 0
      return 'gestern' if offset == 1
      return 'vorgestern' if offset == 2
    end
    return 'letzte Woche' if offset == 7 && days == 7
    return "#{days} Tage" if offset == 0
    return "(benutzerdefiniert)"
  end
end
