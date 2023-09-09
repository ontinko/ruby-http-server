# frozen_string_literal: true

require 'socket'
require 'json'
require_relative 'request'
require_relative 'router'
require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'

class Server
  def initialize(port, max_connections: 10)
    @router = Router.new
    @server = TCPServer.new(port)
    @max_connections = max_connections
    @active_connections = 0
    @mutex = Mutex.new

    @error_actions = {
      service_unavailable: proc { |req| req.json({ error: 'Service unavailable' }, status: 503) },
      internal_error: proc do |request, e|
                        request.json({ error: e&.message || 'Something went wrong' }, status: 500)
                      end,
      not_found: proc { |request| request.json({ error: 'Not found' }, status: 404) },
      method_not_allowed: proc { |request| request.json({ error: 'Method not allowed' }, status: 405) }
    }
  end

  def run
    loop do
      client = @server.accept
      if @mutex.synchronize { @active_connections < @max_connections ? @active_connections += 1 : false }
        Thread.new do
          handle_request(client)
        ensure
          @mutex.synchronize { @active_connections -= 1 }
        end
      else
        @error_actions[:service_unavailable].call(Request.new(client))
      end
    end
  rescue Interrupt
    puts "\nStopping the server..."
    exit
  end

  def get(path, &action)
    @router.define_route(:get, path, &action)
  end

  def post(path, &action)
    @router.define_route(:post, path, &action)
  end

  def put(path, &action)
    @router.define_route(:put, path, &action)
  end

  def patch(path, &action)
    @router.define_route(:patch, path, &action)
  end

  def delete(path, &action)
    @router.define_route(:delete, path, &action)
  end

  def internal_error(&action)
    @error_actions[:internal_error] = action
  end

  def not_found(&action)
    @error_actions[:not_found] = action
  end

  def method_not_allowed(&action)
    @error_actions[:method_not_allowed] = action
  end

  private

  def handle_request(client)
    request = Request.new(client)
    request.prepare

    @router.handle_request(request)
  rescue InternalError, MethodNotAllowed => e
    if e.instance_of? InternalError
      @error_actions[:internal_error].call(request, e)
    elsif e.instance_of? MethodNotAllowed
      @error_actions[:method_not_allowed].call(request)
    end
  end
end
