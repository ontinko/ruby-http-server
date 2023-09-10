# frozen_string_literal: true

require_relative 'request_parser'
require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'
require_relative 'errors/not_found'

class Router
  attr_reader :routes

  def initialize
    @routes = {}
  end

  def handle_request(req)
    action = match_action(req.path, req.method)
    action.call(req)
  end

  def define_route(method, path, &action)
    current_route = @routes
    normalize_path(path).each do |subpath|
      current_route[subpath] = {} unless current_route[subpath]
      current_route = current_route[subpath]
    end

    current_route[''] = {} unless current_route['']
    current_route[''][method] = action
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

  def normalize_path(path)
    RequestParser.normalize_path(path).split('/')
  end

  def match_action(path, method)
    current_route = @routes
    normalize_path(path).each do |subpath|
      if current_route[subpath]
        current_route = current_route[subpath]
        next
      end

      key = current_route.keys.find { |k| k.start_with?(':') }
      raise NotFound unless key

      current_route = current_route[key]
    end

    methods = current_route['']
    raise NotFound unless methods

    action = methods[method]
    raise MethodNotAllowed unless action

    action
  end
end
