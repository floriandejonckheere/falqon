---
layout: home
title: Configuration
nav_order: 2
---

# Configuration

Falqon can be configured before use, by leveraging the `Falqon.configure` method.
It's recommended to configure Falqon in an initializer file, such as `config/initializers/falqon.rb`.
In a Rails application, the generator can be used to create the initializer file:

```bash
rails generate falqon:install
```

Otherwise, the file can be created manually:

```ruby
Falqon.configure do |config|
  # Configure global queue name prefix
  # config.prefix = ENV.fetch("FALQON_PREFIX", "falqon")

  # Retry strategy (none or linear)
  # config.retry_strategy = :linear

  # Maximum number of retries before a message is discarded (-1 for infinite retries)
  # config.max_retries = 3

  # Retry delay (in seconds) for linear retry strategy (defaults to 0)
  # config.retry_delay = 60

  # Configure Redis connection pool (defaults to $REDIS_URL)
  # config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }

  # Configure logger
  # config.logger = Logger.new(STDOUT)
end
```

The values above are the default values.

In addition, it is recommended to configure Redis to be persistent in production environments, in order not to lose data.
Refer to the [Redis documentation](https://redis.io/docs/management/persistence/) for more information.
