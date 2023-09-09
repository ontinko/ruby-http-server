# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'

class Router
  def initialize
    @routes = {}
  end

  def handle_request(req)
    action = match_action(req.path, @routes)
    action.call(req)
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

  def match_action(path, routes); end

  def define_route(method, path, &action); end
end
