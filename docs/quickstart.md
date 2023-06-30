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

See [configuration](configuration.md) if you want to configure Falqon.

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
If the block raises a `Falqon::Error` exception, the message will be retried according to the configured retry strategy.

The return-style `pop` method immediately acknowledges the message before returning it.

## Retry strategy

A retry strategy can be configured to determine how a message should be retried before being discarded.
The following strategies are available:
- `none`: the message will not be retried and will be discarded immediately
- `linear`: the message will be retried a maximum of `max_retries` times before being discarded
