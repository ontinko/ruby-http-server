# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'

class Router
  def initialize
    @error_actions = {
      service_unavailable: proc { |req| req.json({ error: 'Service unavailable' }, status: 503) },
      internal_error: proc do |request, e|
                        request.json({ error: e&.message || 'Something went wrong' }, status: 500)
                      end,
      not_found: proc { |request| request.json({ error: 'Not found' }, status: 404) },
      method_not_allowed: proc { |request| request.json({ error: 'Method not allowed' }, status: 405) }
    }
    @routes = {}
  end

  def handle_request(req)
    action = match_action(req.path, @routes)
    action.call(req)
  rescue InternalError, MethodNotAllowed => e
    if e.instance_of? InternalError
      @error_actions[:internal_error].call(request, e)
    elsif e.instance_of? MethodNotAllowed
      @error_actions[:method_not_allowed].call(request)
    end
  end

  def handle_service_unavailable(req)
    @error_actions[:service_unavailable].call(req)
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

  def error_action(path)
    return @error_actions[:not_found] unless @paths.key?(path)

    @error_actions[:method_not_allowed]
  end
end
