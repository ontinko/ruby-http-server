# frozen_string_literal: true

require 'socket'
require 'json'
require_relative 'request'
require_relative 'multithreader'
require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'

class Server
  def initialize(port)
    @server = TCPServer.new(port)

    @error_actions = {
      server_unavailable: proc { |req| req.respond({ error: 'Service unavailable' }, status: 503) },
      internal_error: proc do |request, e|
                        request.respond({ error: e&.message || 'Something went wrong' }, status: 500)
                      end,
      not_found: proc { |request| request.respond({ error: 'Not found' }, status: 404) },
      method_not_allowed: proc { |request| request.respond({ error: 'Method not allowed' }, status: 405) }
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
    Multithreader.call { handle_request }
  rescue Interrupt
    puts "\nStopping the server..."
    exit
  end

  def get(path, &action)
    @http_actions[:get][path] = action
    add_method_to_path(path, :get)
  end

  def post(path, &action)
    @http_actions[:post][path] = action
    add_method_to_path(path, :post)
  end

  def put(path, &action)
    @http_actions[:put][path] = action
    add_method_to_path(path, :put)
  end

  def patch(path, &action)
    @http_actions[:patch][path] = action
    add_method_to_path(path, :patch)
  end

  def delete(path, &action)
    @http_actions[:delete][path] = action
    add_method_to_path(path, :delete)
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

  def handle_request
    client = @server.accept
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

  def error_action(path)
    return @error_actions[:not_found] unless @paths.key?(path)

    @error_actions[:method_not_allowed]
  end

  def add_method_to_path(path, method)
    if @paths[path]
      @paths[path] << method unless @paths[path].include?(method)
    else
      @paths[path] = [method]
    end
  end
end
