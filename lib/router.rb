# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'
require_relative 'errors/not_found'

class Router
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

  private

  def def_route(method, path, routes, &action)
    if path.empty?
      return routes[path][method] = action if routes[path]

      return routes[path] = { method => action }
    end

    current_path, next_path = path.split('/', 2)
    current_path ||= ''
    routes[current_path] = {} unless routes[current_path]
    next_routes = routes[current_path]

    def_route(method, next_path || '', next_routes, &action)
  end

  def match_action(path, method, routes)
    if path.empty?
      action = routes[path][method]
      raise MethodNotAllowed unless action

      return action
    end

    current_path, next_path = path.split('/', 2)
    next_routes = routes[current_path || '']

    return match_action(next_path || '', method, next_routes) if next_routes

    next_routes = routes[routes.keys.find { |k| k[0] == ':' }]

    raise NotFound unless next_routes

    match_action(next_path || '', method, next_routes)
  end
end
