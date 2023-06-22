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
  config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: "redis://localhost:6379/0") }
end
```

## Usage

```ruby
require "falqon"

# TODO
```


## Testing

```ssh
# Run test suite
bundle exec rspec
```

## Releasing

To release a new version, update the version number in `lib/falqon/version.rb`, update the changelog, commit the files and create a git tag starting with `v`, and push it to the repository.
Github Actions will automatically run the test suite, build the `.gem` file and push it to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/floriandejonckheere/falqon](https://github.com/floriandejonckheere/falqon). 

## License

The software is available as open source under the terms of the [LGPLv3 License](https://www.gnu.org/licenses/lgpl-3.0.html).
