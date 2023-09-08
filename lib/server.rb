# frozen_string_literal: true

require 'socket'
require 'json'
require_relative 'request'
require_relative 'errors/internal_error'

class Server
  def initialize(port)
    @server = TCPServer.new(port)

    @error_mapping = {
      server_error_action: proc { |request, e|
                             request.respond({ error: e&.message || 'Something went wrong' }, status: 500)
                           },
      not_found_action: proc { |request| request.respond({ error: 'Not found' }, status: 404) }
    }

    @http_actions = {
      get: {},
      post: {}
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

  def post(path, &action)
    @http_actions[:post][path] = action
  end

  def server_error(&action)
    @error_mapping[:server_error_action] = action
  end

  def not_found(&action)
    @error_mapping[:not_found_action] = action
  end
end
