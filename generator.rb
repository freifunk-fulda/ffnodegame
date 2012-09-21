#!/usr/bin/env ruby
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

require 'json'

require './settings'

class Generator
  #run one update cycle and generate scores.json
  def self.execute
    #load current scores or fall back to empty array
    scores = nil
    begin
      scores = JSON.parse File.readlines("public/scores.json").join
    rescue
      scores = []
    end

    #load node data
    jsonstr = nil
    begin
      jsonstr = Net::HTTP.get(URI(JSONSRC))
    rescue
      puts 'Failed loading node data! Retrying next round!'
      return
    end

    data = JSON.parse jsonstr
    snapshot = transform data
    update scores, snapshot

    scores.sort_by! {|s| s['points']}.reverse!
    File.write "public/scores.json", JSON.generate(scores)
  end

  private

  #clean and prepare node data
  def self.transform(nodejson)
    nodes = nodejson['nodes'].dup
    links = nodejson['links'].dup

    nodes.each do |n|
      n['meshs']=[]
      n['vpns']=[]
      n['clients']=0
    end

    links.each do |l|
      t = l['type']
      src = l['source']
      dst = l['target']

      if t.nil? #meshing
        quality=l['quality'].split(", ").map(&:to_f)
        nodes[src]['meshs'] << quality[0]
        nodes[dst]['meshs'] << quality[1] if quality.size>1
      elsif t=='vpn'
        quality=l['quality'].split(", ").map(&:to_f)
        nodes[src]['vpns'] << quality[0]
        nodes[dst]['vpns'] << quality[1] if quality.size>1
      elsif t=='client'
        nodes[src]['clients'] += 1
        nodes[dst]['clients'] += 1
      end
    end

    #remove clients
    routers = nodes.select{|n| n['flags']['client'] == false}

    #remove unneccesary stuff
    routers.each do |r|
      r['flags'].delete 'client' #no clients in array anyway
      r['flags'].delete 'vpn' #not used
      r.delete 'geo'  #not interesting
      r.delete 'macs' #not interesting
    end
    return routers
  end

  #calculate points for current round
  def self.calc_points(node)
    points = 0
    points += SC_OFFLINE if !node['flags']['online']  #offline penalty
    points += SC_GATEWAY if node['flags']['gateway']
    points += SC_PERCLIENT * node['clients']
    points += node['vpns'].map{|e| SC_PERVPN / e}.inject(&:+).to_i
    points += node['meshs'].map{|e| SC_PERMESH / e}.inject(&:+).to_i
    return points
  end

  #update scores, add new nodes, remove old nodes with <=0 points
  def self.update(scores, data)
    data.each do |n|
      i = scores.index{|s| s['id'] == n['id'] }
      if i.nil? #new entry
        scores.push n
        scores[-1]['points'] = calc_points n
      elsif #update preserving points and bonus info
        p = scores[i]['points']
        scores[i] = n
        scores[i]['points'] = p + calc_points(n)
      end
    end

    #return without losers and nameless routers
    scores.delete_if{|s| s['points']<=0}
    scores.delete_if{|s| s['name']==''}
    return scores
  end
end
