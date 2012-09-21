#!/usr/bin/env ruby
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

require './generator'
require './settings'

class Updater
  @@updater = nil

  def self.start
    return false if self.running?  #already running

    @@updater = Thread.new do
      Thread.current[:stop] = false
      Thread.current[:running] = true
      puts 'Started updater thread!'
      loop do
        puts 'Perform score update...' if DEBUG
        Generator.execute
        puts 'Scores updated!' if DEBUG

        INTERVAL.times do
          20.times do
            sleep 5
            print '.' if DEBUG
            if Thread.current[:stop]
              Thread.current[:running]=false
              puts 'Stopped updater thread!'
              Thread.exit
            end
          end
          puts if DEBUG
        end
        puts if DEBUG
      end
    end
    return true #started
  end

  def self.stop
    @@updater[:stop] = true
  end

  def self.running?
    return @@updater && @@updater[:running]
  end
end
