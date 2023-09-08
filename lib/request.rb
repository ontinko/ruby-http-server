# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'request_parser'
require 'uri'
require 'pry'

class Request
  attr_reader :method, :path, :query, :headers, :body, :full_path

  SUPPORTED_METHODS = %i[get post].freeze
  METHODS_WITH_BODY = %i[post].freeze

  def initialize(client)
    @client = client
    @query = {}
    @body = nil
    @headers = nil
  end

  # Exists to avoid throwing errors during initialization, must be run after initialize
  def prepare
    start_line_data = RequestParser.parse_start_line(@client)
    @method = start_line_data[:method].downcase.to_sym
    @full_path = start_line_data[:uri_string]
    parsed_full_path = RequestParser.parse_full_path(@full_path)

    @path = parsed_full_path[:path]
    @query = parsed_full_path[:query]
    @headers = RequestParser.parse_headers(@client)
    raise InternalError, "Invalid request method: #{@method}" unless SUPPORTED_METHODS.include?(@method)

      @body = METHODS_WITH_BODY.include?(@method) ? RequestParser.parse_body(@client, headers['content-type'], headers['content-length'].to_i) : nil
  end

  def respond(data = nil, status: nil)
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
end
