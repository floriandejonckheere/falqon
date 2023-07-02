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

The default configuration works out of the box with the provided `docker-compose.yml` file.
See [configuration](configuration.md) if you want to adjust the configuration.

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

For more comprehensive examples, see the [`examples/` directory](https://github.com/floriandejonckheere/falqon/tree/master/examples) in the repository.
