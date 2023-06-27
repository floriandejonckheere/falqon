---
layout: home
title: Quickstart
nav_order: 1
---

# Quickstart

## Requirements

Falqon requires a Redis 6+ server to be available.
Use the [`docker-compose.yml`](https://github.com/floriandejonckheere/falqon/blob/master/docker-compose.yml) file to quickly spin up a Redis server.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "falqon"
```

And then execute:

    $ bundle install

Or install it yourself as:
    
        $ gem install falqon

## Configuration

Falqon can be configured before use, by leveraging the `Falqon.configure` method.
It's recommended to configure Falqon in an initializer file, such as `config/initializers/falqon.rb`.

```ruby
Falqon.configure do |config|
  # Configure queue name prefix
  # config.prefix = "falqon"
  
  # Configure Redis connection pool (defaults to $REDIS_URL)
  # config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: "redis://localhost:6379/0") }

  # Configure logger
  # config.logger = Logger.new(STDOUT)
end
```

## Usage

```ruby
require "falqon"

queue = Falqon::Queue.new("my_queue")

# Push a message to the queue
queue.push("Hello, world!", "Hello, world again!")

# Pop a message from the queue (return style)
puts queue.pop # => "Hello, world!"

queue.empty? # => false

queue.peek # => "Hello, world again!"

# Pop a message from the queue (block style)
queue.pop do |message|
  puts message # => "Hello, world again!"
  
  # Raising a Falqon::Error exception will cause the message to be requeued
  raise Falqon::Error, "Something went wrong"
end

queue.empty? # => false

puts queue.pop # => "Hello, world again!"

queue.empty? # => true

queue.peek # => nil
```

## Acknowledgement

When using the block-style `pop` method, the message will be acknowledged when the block returns without raising a `Falqon::Error` exception.
Acknowledgement will remove the message and its data from the queue.
If the block raises a `Falqon::Error` exception, the message will be requeued at the end of the queue.

The return-style `pop` method immediately acknowledges the message before returning it.
