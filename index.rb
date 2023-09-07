# frozen_string_literal: true

require_relative 'server'
require 'pry'

server = Server.new(4000)

server.get('/') do |request|
  request.respond(data: { data: 'Welcome!' })
end

server.get('/home') do |request|
  if request.query[:week]
    request.respond(data: { data: request.query[:week] }) if request.query[:week]
  else
    request.respond(data: { data: 'You are home!' })
  end
end

server.run
