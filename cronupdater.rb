#!/usr/bin/env ruby
#Script to be used with cron to update the scores.json in the background
require './scores'

log 'Start score update...'

result = false
failed = 0
while !result
  begin
    result = Scores.update
  rescue
    result = false
  end
  if !result && failed < 10
    failed += 1
    log 'Failed loading node data! Retrying in 60 seconds...'
    sleep 60
  end
end

if !result
  log 'Could not update :('
  return
end

log 'Scores updated!'

