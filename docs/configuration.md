---
layout: home
title: Configuration
nav_order: 2
---

# Configuration

Falqon can be configured before use, by leveraging the `Falqon.configure` method.
It's recommended to configure Falqon in an initializer file, such as `config/initializers/falqon.rb`.

```ruby
Falqon.configure do |config|
  # Configure global queue name prefix
  # config.prefix = "falqon"

  # Retry strategy (none or linear)
  # config.retry_strategy = :linear

  # Maximum number of retries before a message is discarded
  # config.max_retries = 3

  # Configure Redis connection pool (defaults to $REDIS_URL)
  # config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: "redis://localhost:6379/0") }

  # Configure logger
  # config.logger = Logger.new(STDOUT)
end
```

The values above are the default values.

In addition, it is recommended to configure Redis to be persistent in production environments, in order not to lose data.
Refer to the [Redis documentation](https://redis.io/docs/management/persistence/) for more information.
