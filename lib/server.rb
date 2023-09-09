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
        @router.handle_service_unavailable(Request.new(client))
      end
    end
  rescue Interrupt
    puts "\nStopping the server..."
    exit
  end

  def get(path, &action)
    @router.get(path, &action)
  end

  def post(path, &action)
    @router.post(:post, path, &action)
  end

  def put(path, &action)
    @router.put(:put, path, &action)
  end

  def patch(path, &action)
    @router.patch(:patch, path, &action)
  end

  def delete(path, &action)
    @router.delete(:delete, path, &action)
  end

  def internal_error(&action)
    @router.internal_error(&action)
  end

  def not_found(&action)
    @router.not_found(&action)
  end

  def method_not_allowed(&action)
    @router.method_not_allowed(&action)
  end

  private

  def handle_request(client)
    request = Request.new(client)
    request.prepare

    @router.handle_request(request)
  end
end
