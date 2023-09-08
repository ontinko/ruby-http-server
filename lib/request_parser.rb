# frozen_string_literal: true

require 'json'
require 'uri'

class RequestParser
  class << self
    def parse_start_line(req)
      result = {}

      data = req.gets.split
      result[:method] = data[0].to_s
      result[:uri_string] = data[1]

      result
    end

    def parse_headers(req)
      data = {}

      loop do
        line = req.gets
        break if line.chomp.empty?

        parsed = line.split(':', 2).map { |s| s.chomp.strip }
        data[parsed[0].downcase] = parsed[1]
      end

      data
    end

    def parse_body(req, content_type, content_length)
      return nil if content_type.nil?

      case content_type
      when 'application/json'
        parse_json(req, content_length)
      else
        raise InternalError, 'Content type not supported'
      end
    end

    def parse_full_path(full_path)
      result = {
        path: '',
        query: ''
      }

      path, query = full_path.split('?')
      stripped_path = path.sub(%r{/*$}, '')

      result[:path] = stripped_path.empty? ? '/' : stripped_path
      result[:query] = parse_query(query)

      result
    end

    private

    def parse_json(req, content_length)
      raise InternalError, 'Unspecified Content-Length header for application/json' if content_length.nil?

      raw_data = req.read(content_length)

      JSON.parse(raw_data)
    rescue JSON::ParserError
      raise InternalError, 'Invalid JSON data'
    end

    def parse_query(string)
      result = {}

      return {} if string.nil? || string.empty?

      decode_uri(string).split(/&|;/).each do |pair|
        key, value = pair.split('=')
        parsed_value = value&.split(',')

        if parsed_value && parsed_value.size > 1
          result[key.to_sym] = parsed_value
          next
        end

        result[key.to_sym] = value
      end

      result
    end

    def decode_uri(str)
      URI.decode_uri_component(str)
    end
  end
end
