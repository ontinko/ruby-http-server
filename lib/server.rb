# frozen_string_literal: true

require 'socket'
require 'json'
require_relative 'request'
require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'

class Server
  def initialize(port, max_connections: 10)
    @server = TCPServer.new(port)
    @max_connections = max_connections
    @active_connections = 0
    @mutex = Mutex.new

    @error_actions = {
      server_unavailable: proc { |req| req.json({ error: 'Service unavailable' }, status: 503) },
      internal_error: proc do |request, e|
                        request.json({ error: e&.message || 'Something went wrong' }, status: 500)
                      end,
      not_found: proc { |request| request.json({ error: 'Not found' }, status: 404) },
      method_not_allowed: proc { |request| request.json({ error: 'Method not allowed' }, status: 405) }
    }

    @paths = {}

    @http_actions = {
      get: {},
      post: {},
      put: {},
      patch: {},
      delete: {}
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
        @error_actions[:server_unavailable].call(Request.new(client))
      end
    end
  rescue Interrupt
    puts "\nStopping the server..."
    exit
  end

  def get(path, &action)
    define_route(:get, path, &action)
  end

  def post(path, &action)
    define_route(:post, path, &action)
  end

  def put(path, &action)
    define_route(:put, path, &action)
  end

  def patch(path, &action)
    define_route(:patch, path, &action)
  end

  def delete(path, &action)
    define_route(:delete, path, &action)
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

    action = @http_actions[request.method][request.path] || error_action(request.path)
    action.call(request)
  rescue InternalError, MethodNotAllowed => e
    if e.instance_of? InternalError
      @error_actions[:internal_error].call(request, e)
    elsif e.instance_of? MethodNotAllowed
      @error_actions[:method_not_allowed].call(request)
    end
  end

  def define_route(method, path, &action)
    @http_actions[method][path] = action
    add_method_to_path(path, method)
  end

  def add_method_to_path(path, method)
    if @paths[path]
      @paths[path] << method unless @paths[path].include?(method)
    else
      @paths[path] = [method]
    end
  end

  def error_action(path)
    return @error_actions[:not_found] unless @paths.key?(path)

    @error_actions[:method_not_allowed]
  end
end
