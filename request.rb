# frozen_string_literal: true

require_relative 'errors/internal_error'
require 'uri'

class Request
  attr_reader :method, :path, :query

  def initialize(client)
    @error = ''
    @client = client
    @query = {}
  end

  def respond(status: nil, data: nil)
    response = []
    response << "HTTP/1.1 #{status || 200}\r\n"
    if data
      response << "Content-Type: application/json\r\n\n"
      response << "#{data.to_json}\r"
    end
    response << "\n"
    @client.write(response.join)
    @client.close
  end

  # Exists to avoid throwing errors during initialization, must be run after initialize
  def prepare
    parse_head
    @data = read_request_data
  end

  private

  def parse_head
    data = @client.gets.split
    method = data[0]
    parse_path(data[1])
    case method
    when 'GET' then @method = :get
    else
      raise InternalError, "Invalid request method: #{method}"
    end
  end

  def parse_path(full_path)
    path, query = full_path.split('?')
    @path = path.sub(%r{/*$}, '')
    return if query.nil?

    parse_query(query)
  end

  def parse_query(string)
    URI.decode_uri_component(string).split(/&|;/).each do |pair|
      key, value = pair.split('=')
      parsed_value = value&.split(',')

      if parsed_value && parsed_value.size > 1
        @query[key.to_sym] = parsed_value
        next
      end

      @query[key.to_sym] = value
    end

    @query = result
  end

  def read_request_data
    case @method
    when :get then read_get
    end
  end

  def read_get
    data = []

    loop do
      line = @client.gets
      break if line.chomp.empty?

      data << line
    end

    data
  end
end
