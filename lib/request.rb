# frozen_string_literal: true

require_relative 'errors/internal_error'
require_relative 'errors/method_not_allowed'
require_relative 'request_parser'
require 'uri'

class Request
  attr_reader :method, :path, :params, :query, :headers, :body, :full_path

  SUPPORTED_METHODS = %i[get post put delete patch].freeze
  METHODS_WITH_BODY = %i[post put patch].freeze

  def initialize(client, router)
    @client = client
    @router = router
    @query = {}
    @params = {}
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
    @params = @router.params_for_path(@path)
    @query = parsed_full_path[:query]
    @headers = RequestParser.parse_headers(@client)
    raise MethodNotAllowed unless SUPPORTED_METHODS.include?(@method)

    return unless METHODS_WITH_BODY.include?(@method)

    @body = RequestParser.parse_body(@client, headers['content-type'], headers['content-length'].to_i)
  end

  def json(data, status: 200)
    response = []
    response << "HTTP/1.1 #{status}\r\n"
    response << "Content-Type: application/json\r\n\n"
    response << "#{data.to_json}\r\n"
    @client.write(response.join)
    @client.close
  end

  def status(status = 200)
    response = "HTTP/1.1 #{status}\r\n"
    @client.write(response)
    @client.close
  end

  def redirect(path)
    response = []
    response << "HTTP/1.1 302\r\n"
    response << "Location: #{path}\r\n\n"
    @client.write(response.join)
    @client.close
  end
end
