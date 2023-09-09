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

  def define_route(method, path, &action); end

  private

  def match_action(path, routes); end
end
