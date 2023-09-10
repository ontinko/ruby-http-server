# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'
require_relative 'errors/not_found'

class Router
  attr_reader :routes

  def initialize
    @routes = {}
  end

  def handle_request(req)
    action = match_action(req.path, req.method, @routes)
    action.call(req)
  end

  def define_route(method, path, routes = @routes, &action)
    def_route(method, path.sub(%r{^/*(.*?)/*$}, '\1'), routes, &action)
  end

  def params_for_path(path)
    params = {}
    current_route = @routes
    path.split('/').each do |subpath|
      unless current_route[subpath].nil?
        current_route = current_route[subpath]
        next
      end

      key = current_route.keys.find { |k| k.start_with?(':') }
      break if key.nil?

      current_route = current_route[key]
      params[key[1..].to_sym] = subpath
    end

    params
  end

  private

  def def_route(method, path, routes, &action)
    if path.empty?
      return routes[path][method] = action if routes[path]

      return routes[path] = { method => action }
    end

    current_path, next_path = path.split('/', 2)
    next_path ||= ''
    routes[current_path] = {} unless routes[current_path]
    next_routes = routes[current_path]

    def_route(method, next_path, next_routes, &action)
  end

  def match_action(path, method, routes)
    if path.empty?
      raise NotFound unless routes && routes[path]

      action = routes[path][method]
      raise MethodNotAllowed unless action

      return action
    end

    split_path = path.split('/', 2)
    current_path = split_path[0]
    next_path = split_path[1] || ''
    next_routes = routes[current_path] || routes[routes.keys.find { |k| k.start_with?(':') }]

    match_action(next_path, method, next_routes)
  end
end
