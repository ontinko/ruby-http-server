# frozen_string_literal: true

require_relative 'server'

server = Server.new(4000)

server.get('/') do |request|
  request.respond(data: { data: 'Welcome!' })
end

server.get('/home') do |request|
  request.respond(data: { data: 'You are home!' })
end

server.run
