# frozen_string_literal: true

require_relative 'lib/server'
require 'pry'

server = Server.new(4000)

server.get('/') do |request|
  request.respond({ data: 'Welcome!' })
end

server.get('/home') do |request|
  if request.query[:week]
    request.respond({ data: request.query[:week] }) if request.query[:week]
  else
    request.respond({ data: 'You are home!' })
  end
end

server.run
