#!/usr/bin/env ruby
require 'pry'
require 'csv'
FILENAME = /^[^:]*/
LINENUM = /[:]{1}[0-9]*[^:]*/

def find_invocations(service)
  path = "#{__dir__}/lib/#{service}"

  methods = %w[:get :post :put :delete :destroy :update]
  search_token = methods.join('|')

  cmd = `rg '#{search_token}' #{path} -U --no-heading --line-number -H`
end

services = %w[appeals bb central_mail decision_review emis evss facilities forms gi hca ihub mhv_ac mvi preneeds reports rx search sm vet360 vic]

map = { counts: { total: 0 }}
services.each do |service|
  map[service] = find_invocations(service).split("\n")
  map[:counts][service] = map[service].count
  map[:counts][:total] += map[service].count

  map[service].each_with_index do |match, i|
    matches = FILENAME.match(match)
    post_match = matches.post_match
    file, line, post = matches[0], post_match.split(" ")[0], post_match.split(" ")[1..post_match.length]
    map[service][i] = [file, line, post]
  end
end

binding.pry
pp map['appeals']

conn = Faraday.new('https://keifer.io') do |f|
  f.use :instrumentation
  f.adapter Faraday.default_adapter
end
