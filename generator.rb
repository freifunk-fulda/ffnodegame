#!/usr/bin/env ruby
#Freifunk node highscore game
#Copyright (C) 2012 Anton Pirogov
#Licensed under The GPLv3

require 'json'
require 'net/http'

require './settings'

class Generator

  #load apple MAC adresses once
  if PUNISHAPPLE
    #NOTE: update the applemacs.txt file with:
    #./queryvendormac.sh apple > applemacs.txt
    @@apples = File.readlines('applemacs.txt').map{|l| l.chomp.strip.downcase}
  end

  #return last update time -> last modification to file
  def self.last_update
    return File.mtime 'public/scores.json'
  rescue
    return Time.new(0)
  end

  #take score file and generate a sorted highscore list for last N days
  def self.generate(days)
    scores = read_scores

    #sum up last N day points
    scores.each{|e| e['points'] = e['points'][0..(days-1)].inject(&:+)}
    #sort by score
    scores.sort_by! {|e| e['points']}.reverse!

    return scores
  end

  #run one update cycle and generate/update scores.json
  def self.execute
    scores = read_scores

    #load node data
    jsonstr = nil
    begin
      jsonstr = Net::HTTP.get(URI(JSONSRC))
    rescue
      return nil #failed!
    end

    #NOTE: filtering and analyzing of JSON data fits perfectly here
    data = JSON.parse jsonstr
    snapshot = transform data
    update scores, snapshot

    scorejson = JSON.generate scores
    File.write "public/scores.json", scorejson
    return scores
  end

  def self.calc_vpn_points(node)
    node['vpns'].map{|e| SC_PERVPN / e}.inject(&:+).to_i
  end

  def self.calc_mesh_points(node)
    node['meshs'].map{|e| SC_PERMESH / e}.inject(&:+).to_i
  end

  private

  #load current score file or fall back to empty array
  def self.read_scores
    scores = nil
    begin
      file = File.open('public/scores.json','r:UTF-8') #because passenger sucks
      scores = JSON.parse file.read
    rescue
      scores = []
    end
    return scores
  end

  #insert fresh new day points entry
  def self.rotate(scores)
    scores.each do |e|
      e['points'].unshift 0
      e['points'].pop if e['points'].length > 30
    end
  end

  #clean and prepare node data
  def self.transform(nodejson)
    nodes = nodejson['nodes']
    links = nodejson['links']

    nodes.each do |n|
      n['meshs']=[]
      n['vpns']=[]
      n['clients']=0
      n['apples']=0
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

        if PUNISHAPPLE
          if is_apple(nodes[src]) || is_apple(nodes[dst])
            nodes[src]['apples'] += 1
            nodes[dst]['apples'] += 1
          end
        end
      end
    end

    #remove clients
    routers = nodes.select{|n| n['flags']['client'] == false}

    #remove unneccesary stuff from router score json
    routers.each do |r|
      r['flags'].delete 'client' #no clients in array anyway
      r['flags'].delete 'vpn' #not used
      r.delete 'geo'  #not interesting
      r.delete 'macs' #not interesting
      r.delete 'id' #not interesting
    end

    return routers
  end

  #decide by MAC address
  def self.is_apple(node)
    return @@apples.index{|a| a==node['id'][0..7]}
  end

  #calculate sum of points for node in current round
  #NOTE: on calc changes, don't forget to check and update erb file
  def self.calc_points(node)
    points = 0
    points += SC_OFFLINE if !node['flags']['online']  #offline penalty
    points += SC_GATEWAY if node['flags']['gateway']
    points += SC_PERCLIENT * node['clients']
    points += SC_PERAPPLE * node['apples'] if PUNISHAPPLE
    points += calc_vpn_points node
    points += calc_mesh_points node
    return points
  end

  #check whether a node shall be garbage collected
  #-> total sum of points <= 0 OR today way offline for 12 hours
  def self.is_loser?(node)
    sum = node['points'].inject(&:+).to_i
    return true if sum <= 0
    return node['points'][0]<=SC_OFFLINE*12
  end

  #update scores, add new nodes, remove old nodes with <=0 points
  def self.update(scores, data)
    #start new day points field on day change between updates
    rotate scores if last_update.day < Time.now.day

    #garbage collection:
    #detect nodes which are gone from source data (by name so node renames affected too)
    #and let them slowly die (by offline penalty)
    scores.select{|s| !data.index{|d| d['name']==s['name']}}.each do |s|
      s['flags']['online']=false
      s['flags']['gateway']=false
      s['vpns'] = []
      s['meshs'] = []
      s['clients'] = 0
      s['apples'] = 0
      s['points'][0] += calc_points s
    end

    #perform regular update
    data.each do |n|
      i = scores.index{|s| s['name'] == n['name'] }
      if i.nil? #new entry
        scores.push n
        scores[-1]['points'] = [calc_points(n)]
      elsif #update preserving points array
        p = scores[i]['points']
        scores[i] = n
        scores[i]['points'] = p
        scores[i]['points'][0] += calc_points n
      end
    end

    #return without nameless routers, blacklisted and losers
    scores.delete_if{|s| s['name'].empty?}
    scores.delete_if{|s| BLACKLIST.index s['name']}
    scores.delete_if{|s| is_loser? s}
    return scores
  end
end
