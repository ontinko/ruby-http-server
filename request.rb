SAMPLE_DATA = '<html lang="en-US"><body><h1>Hello from the server!</h1></body></html>'.freeze
ERROR_DATA = '<html lang="en-US"><body><h1>Error lmao</h1></body></html>'.freeze

class Request
  attr_reader :method, :path, :error

  def initialize(client)
    @error = ''
    @client = client
    parse_head
    @data = read_request_data
  end

  def respond(status: nil, data: nil)
    response = ""
    response << "HTTP/1.1 #{status || 200}\r\n"
    if data
      response << "Content-Type: application/json\r\n\n"
      response << "#{data.to_json}\r"
    end
    response << "\n"
    @client.write(response)
    @client.close
  end

  private

  def parse_head
    data = @client.gets.split(' ')
    method = data[0]
    @path = data[1]
    case method
    when 'GET' then @method = :get
    else
      @error = 'Invalid HTTP method'
    end
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
