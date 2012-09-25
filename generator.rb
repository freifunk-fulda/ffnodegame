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

  #run one update cycle and generate scores.json
  def self.execute
    #load current scores or fall back to empty array
    scores = nil
    begin
      file = File.open('public/scores.json','r:UTF-8') #because passenger sucks
      scores = JSON.parse file.read
    rescue
      scores = []
    end

    #load node data
    jsonstr = nil
    begin
      jsonstr = Net::HTTP.get(URI(JSONSRC))
    rescue
      #failed!
      return nil
    end

    #NOTE: filtering and analyzing of JSON data fits perfectly here
    data = JSON.parse jsonstr
    snapshot = transform data
    update scores, snapshot

    scores.sort_by! {|s| s['points']}.reverse!

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

  #update scores, add new nodes, remove old nodes with <=0 points
  def self.update(scores, data)
    #detect nodes which are gone from source data (by name so node renames affected too)
    #and let them slowly die (by offline penalty)
    scores.select{|s| !data.index{|d| d['name']==s['name']}}.each do |s|
      s['flags']['online']=false
      s['flags']['gateway']=false
      s['vpns'] = []
      s['meshs'] = []
      s['clients'] = 0
      s['apples'] = 0
      s['points'] += calc_points s
    end

    #perform regular update
    data.each do |n|
      i = scores.index{|s| s['name'] == n['name'] }
      if i.nil? #new entry
        scores.push n
        scores[-1]['points'] = calc_points n
      elsif #update preserving points
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
