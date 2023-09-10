# Simple HTTP server written in Ruby (WIP)

## Note

This is a personal project made to learn more about webdev and Ruby, and is not intended for any use in the real world. 
If for whatever weird reason you are thinking about using this in production, please don't.

Cheers.

## Requirements

 * bundler
 * ruby 3.1.2

## Usage

1. Import `server.rb` file into your code

```ruby
require_relative 'path/to/server'
```

2. Create the server and bind it to the post you like

```ruby
server = Server.new(3000)
```

You can also define how many concurrent connections the server can handle:

```ruby
server = Server.new(3000, max_connections: 100)
```

3. Define actions for your routes

```ruby
server.get('/home') do |req|
  req.json({ data: 'GET request to /home' })
end

server.get('/posts') do |req|
  req.json({ data: 'GET request to /posts' })
end

server.post('/posts') do |req|
  req.json({ data: 'POST request to /posts' })
end
```

You can use `req.params` method to access URL parameters of the request:

```ruby
server.get('/posts/:post_id/comments/:comment_id') do |req|
  req.json({ data: "Viewing commment #{req.params[:comment_id]} to post #{req.params[:post_id]}" })
end
```

Or access query params through `req.query`:

```ruby
server.get('/post/:post_id/comments') do |req|
  sort_by = req.query[:sort_by]
  if sort_by
    req.json({ data: "Sorting comments by #{sort_by}" })
  else
    req.json({ data: 'Not sorting comments for now' })
  end
end
```

You can also use `Request::redirect` method as follows

```ruby
server.get('/') do |req|
  req.redirect('/home')
end
```

4. Define actions for errors

```ruby
server.not_found do |req|
  req.json({ error: 'Not Found' }, status: 404)
end

server.internal_error do |req, e|
  req.json({ error: "Internal error #{e.message}" }, status: 500)
end
```

5. Run the server

```ruby
server.run
```
