# Falqon
[![Continuous Integration](https://github.com/floriandejonckheere/falqon/actions/workflows/ci.yml/badge.svg)](https://github.com/floriandejonckheere/falqon/actions/workflows/ci.yml)
![Release](https://img.shields.io/github/v/release/floriandejonckheere/falqon?label=Latest%20release)

Simple, efficient, and reliable messaging queue for Ruby.

Falqon is a simple messaging queue implementation, backed by the in-memory Redis key-value store.
It exposes a simple Ruby API to send and receive messages between different processes, between threads in the same process, or even fibers in the same thread.
It is perfect when you require a lightweight solution for processing messages, but don't want to deal with the complexity of a full-blown message queue like RabbitMQ or Kafka.

See the [documentation](https://docs.falqon.dev) for more information on how to use Falqon in your application.

## Features

Falqon offers an elegant solution for messaging queues in Ruby.

- Elegant: only two methods to send and receive messages
- Reliable: no data is lost when a client crashes unexpectedly
- Fast: Falqon is built on top of Redis, a fast in-memory data store
- Flexible: tune the behaviour of the queue to your needs

## Get started

- Install Falqon and get working with messaging queues in a heartbeat using the [quickstart guide](#quickstart)
- Check out the [API documentation](https://docs.falqon.dev/) for more information on how to use Falqon in your application
- Check out the CLI documentation](https://docs.falqon.dev/) for more information on how to manage queues and messages from the command line
- Read the [architecture documentation](#architecture) to learn more about how Falqon works under the hood

## Quickstart

### Requirements

Falqon requires a Redis 6+ server to be available.
Use the [docker-compose.yml](https://github.com/floriandejonckheere/falqon/blob/master/docker-compose.yml) file to quickly spin up a Redis server.

### Installation

Add this line to your application's Gemfile:

```ruby
gem "falqon"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install falqon

### Configuration

The default configuration works out of the box with the provided `docker-compose.yml` file.
See [configuration](#configuration) if you want to adjust the configuration.

### Usage

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

For more comprehensive examples, see the [examples directory](examples/) in the repository.

## Architecture

A queue is identified with a name, which is used as a key prefix.
Queues are stored in Redis as a list of incrementing integers representing unique message identifiers.
The messages itself are stored in Redis as strings.

The following Redis keys are used to store data.

- `[{prefix}:]queues`: set of queue names

- `[{prefix}/]{name}`: list of message identifiers on the (pending) queue

- `[{prefix}/]{name}:id`: message identifier sequence

- `[{prefix}/]{name}:processing`: list of message identifiers being processed

- `[{prefix}/]{name}:scheduled`: list of message identifiers scheduled to retry

- `[{prefix}/]{name}:dead`: list of message identifiers that have been discarded

- `[{prefix}/]{name}:data:{id}`: message data for identifier `{id}`

- `[{prefix}/]{name}:metadata`: metadata for the queue

- `[{prefix}/]{name}:metadata:{id}`: metadata for identifier `{id}`

## Testing

```ssh
# Run test suite
bundle exec rspec
```

## Releasing

To release a new version, update the version number in `lib/falqon/version.rb`, update the changelog, commit the files and create a git tag starting with `v`, and push it to the repository.
Github Actions will automatically run the test suite, build the `.gem` file and push it to [rubygems.org](https://rubygems.org).

## Documentation

The documentation in `docs/` is automatically built by [YARD](https://yardoc.org) and pushed to [docs.falqon.dev](https://docs.falqon.dev) on every push to the `main` branch.
Locally, you can build the documentation using the following commands:

```sh
rake yrad
```

In development, you can start a local server to preview the documentation:

```sh
yard server --reload
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/floriandejonckheere/falqon](https://github.com/floriandejonckheere/falqon). 

## License

The software is available as open source under the terms of the [LGPL-3.0 License](https://www.gnu.org/licenses/lgpl-3.0.html).
