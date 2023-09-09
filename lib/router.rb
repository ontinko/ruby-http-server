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
    if path.nil?
      return routes[nil][method] = action if routes[nil]

      return routes[nil] = { method => action }
    end

    current_path, next_path = path.split('/', 2)
    routes[current_path] = {} unless routes[current_path]
    next_routes = routes[current_path]

    define_route(next_path, method, next_routes)
  end

  private

  def match_action(path, method, routes)
    if path.nil?
      methods = routes[path]
      raise NotFound unless methods

      action = methods[method]
      raise MethodNotAllowed unless action

      return action
    end

    current_path, next_path = path.split('/', 2)
    next_routes = routes[current_path]

    return match_action(next_path, method, next_routes) if next_routes

    next_routes = routes[routes.keys.find { |k| k }[0]]

    return nil unless next_routes

    match_action(next_path, method, next_routes)
  end
end
