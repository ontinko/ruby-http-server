require 'socket'
require 'pry'
require 'json'
require_relative 'request'

class Server
  def initialize(port)
    @server = TCPServer.new(port)
    @get_mapping = {}
  end

  def run
    loop do
      client = @server.accept
      request = Request.new(client)

      unless request.error.empty?
        puts 'Sending error'
        request.respond(status: 400, data: { error: 'Invalid request' })
        next
      end

      case request.method
      when :get
        action = @get_mapping[request.path]
        if action.nil?
          puts 'No such path'
          request.respond(status: 404, data: { error: 'Not found' })
          next
        end

        action.call(request)
      end
    end
  end

  def get(path, &action)
    @get_mapping[path] = action
  end
end
