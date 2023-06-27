# Falqon

![Continuous Integration](https://github.com/floriandejonckheere/falqon/workflows/Continuous%20Integration/badge.svg)
![Release](https://img.shields.io/github/v/release/floriandejonckheere/falqon?label=Latest%20release)

Simple, efficient, and reliable messaging queue for Ruby.

Falqon offers a simple messaging queue implementation backed by Redis.

## Requirements

Falqon requires a Redis 6+ server to be available.

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

Configure Falqon's Redis connection pool before use.
By default, Falqon will initialize a connection pool of size 5 to `redis://localhost:6379/0`.

```ruby
Falqon.configure do |config|
  # Configure queue name prefix
  config.prefix = "falqon"
  
  # Configure Redis connection pool (defaults to $REDIS_URL)
  config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: "redis://localhost:6379/0") }

  # Configure logger
  config.logger = Logger.new(STDOUT)
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

### Acknowledgement

When using the block-style `pop` method, the message will be acknowledged when the block returns without raising a `Falqon::Error` exception.
Acknowledgement will remove the message and its data from the queue.
If the block raises a `Falqon::Error` exception, the message will be requeued at the end of the queue.

The return-style `pop` method immediately acknowledges the message before returning it.

## Testing

```ssh
# Run test suite
bundle exec rspec
```

## Releasing

To release a new version, update the version number in `lib/falqon/version.rb`, update the changelog, commit the files and create a git tag starting with `v`, and push it to the repository.
Github Actions will automatically run the test suite, build the `.gem` file and push it to [rubygems.org](https://rubygems.org).

## Architecture

A queue is identified with a name, which is used as a key prefix.
Queues are stored in Redis as a list of incrementing integers representing unique message identifiers.
The messages itself are stored in Redis as strings.

The following Redis keys are used:
- `{name}`: list of message identifiers on the queue
- `{name}:id`: message identifier sequence
- `{name}:processing`: list of message identifiers being processed
- `{name}:messages:{id}`: message contents for identifier `{id}`
- `{name}:retries:{id}`: retry count for identifier `{id}`

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/floriandejonckheere/falqon](https://github.com/floriandejonckheere/falqon). 

## License

The software is available as open source under the terms of the [LGPLv3 License](https://www.gnu.org/licenses/lgpl-3.0.html).
