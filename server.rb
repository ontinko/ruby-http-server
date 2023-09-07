# frozen_string_literal: true

require 'socket'
require 'pry'
require 'json'
require_relative 'request'
require_relative 'errors/internal_error'

class Server
  def initialize(port)
    @server = TCPServer.new(port)

    @error_mapping = {
      server_error_action: proc { |request, e|
                             request.respond(status: 500, data: { error: e&.message || 'Something went wrong' })
                           },
      not_found_action: proc { |request| request.respond(status: 404, data: { error: 'Something went wrong' }) }
    }

    @http_actions = {
      get: {}
    }
  end

  def run
    loop do
      client = @server.accept
      request = Request.new(client)
      request.prepare

      action = @http_actions[request.method][request.path] || @error_mapping[:not_found_action]
      action.call(request)
    rescue InternalError => e
      @error_mapping[:server_error_action].call(request, e)
    end
  rescue Interrupt
    puts "\nStopping the server..."
    exit
  end

  def get(path, &action)
    @http_actions[:get][path] = action
  end

  def server_error(&action)
    @error_mapping[:server_error_action] = action
  end

  def not_found(&action)
    @error_mapping[:not_found_action] = action
  end
end
