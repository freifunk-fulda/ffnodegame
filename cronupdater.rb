#!/usr/bin/env ruby
#Script to be used with cron to update the scores.json in the background

require './updater'
Updater.update
