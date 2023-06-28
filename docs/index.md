---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: home
title: Home
nav_order: 0
---

# Falqon

Falqon is a simple, efficient, and reliable messaging queue implementation for Ruby.
It offers a simple integration to send and receive messages in your application, backed by Redis.

## Features

Falqon offers an elegant solution for messaging queues in Ruby.

- Elegant API: only two methods to send and receive messages
- Reliable message delivery: no data is lost when a client crashes unexpectedly
- Fast: Falqon is built on top of Redis, a fast in-memory data store
- Message delivery is retried up to a configurable number of times before being discarded

## Get started

- Install Falqon and get working with messaging queues in a heartbeat using the [quickstart guide](quickstart)
- Check out the [API documentation](api) for more information on how to use Falqon in your application
- Read the [architecture documentation](architecture) to learn more about how Falqon works under the hood

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/floriandejonckheere/falqon](https://github.com/floriandejonckheere/falqon). 

## License

The software is available as open source under the terms of the [LGPL-3.0 License](https://www.gnu.org/licenses/lgpl-3.0.html).
