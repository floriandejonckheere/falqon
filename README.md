# Falqon
[![Continuous Integration](https://github.com/floriandejonckheere/falqon/actions/workflows/ci.yml/badge.svg)](https://github.com/floriandejonckheere/falqon/actions/workflows/ci.yml)
![Release](https://img.shields.io/github/v/release/floriandejonckheere/falqon?label=Latest%20release)

Simple, efficient, and reliable messaging queue for Ruby.

Falqon is a simple messaging queue implementation, backed by the in-memory Redis key-value store.
It exposes a simple Ruby API to send and receive messages between different processes, between threads in the same process, or even fibers in the same thread.
It is perfect when you require a lightweight solution for processing messages, but don't want to deal with the complexity of a full-blown message queue like RabbitMQ or Kafka.

See the [documentation](https://docs.falqon.dev) for more information on how to use Falqon in your application.

## Testing

```ssh
# Run test suite
bundle exec rspec
```

## Releasing

To release a new version, update the version number in `lib/falqon/version.rb`, update the changelog, commit the files and create a git tag starting with `v`, and push it to the repository.
Github Actions will automatically run the test suite, build the `.gem` file and push it to [rubygems.org](https://rubygems.org).

## Documentation

The documentation in `docs/` is automatically built by Github Pages and pushed to [docs.falqon.dev](https://docs.falqon.dev) on every push to the `main` branch.
Locally, you can build the documentation using Jekyll:

```sh
$ cd docs
$ docker compose up docs
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/floriandejonckheere/falqon](https://github.com/floriandejonckheere/falqon). 

## License

The software is available as open source under the terms of the [LGPL-3.0 License](https://www.gnu.org/licenses/lgpl-3.0.html).
