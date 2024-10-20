# frozen_string_literal: true

# typed: true

require "logger"

require "redis"
require "connection_pool"

module Falqon
  # Falqon configuration
  #
  # Falqon can be configured before use, by leveraging the +Falqon.configure+ method.
  # It's recommended to configure Falqon in an initializer file, such as +config/initializers/falqon.rb+.
  # In a Rails application, the generator can be used to create the initializer file:
  #
  #   rails generate falqon:install
  #
  # Otherwise, the file can be created manually:
  #
  #   Falqon.configure do |config|
  #     # Configure global queue name prefix
  #     # config.prefix = ENV.fetch("FALQON_PREFIX", "falqon")
  #
  #     # Retry strategy (none or linear)
  #     # config.retry_strategy = :linear
  #
  #     # Maximum number of retries before a message is discarded (-1 for infinite retries)
  #     # config.max_retries = 3
  #
  #     # Retry delay (in seconds) for linear retry strategy (defaults to 0)
  #     # config.retry_delay = 60
  #
  #     # Configure the Redis client options
  #     # config.redis_options = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
  #
  #     # Or, configure the Redis client directly
  #     # config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }
  #
  #     # Configure logger
  #     # config.logger = Logger.new(STDOUT)
  #   end
  #
  # The values above are the default values.
  #
  # In addition, it is recommended to configure Redis to be persistent in production environments, in order not to lose data.
  # Refer to the {https://redis.io/docs/management/persistence Redis documentation} for more information.
  #
  class Configuration
    extend T::Sig

    # Queue name prefix
    sig { params(prefix: String).returns(String) }
    attr_writer :prefix

    # Maximum number of retries before a message is discarded
    sig { params(max_retries: Integer).returns(Integer) }
    attr_writer :max_retries

    # Delay between retries (in seconds)
    sig { params(retry_delay: Integer).returns(Integer) }
    attr_writer :retry_delay

    # Redis connection pool
    sig { params(redis: ConnectionPool).returns(ConnectionPool) }
    attr_writer :redis

    # Redis connection options
    sig { params(redis_options: Hash).returns(Hash) }
    attr_writer :redis_options

    # Logger instance
    sig { params(logger: Logger).returns(Logger) }
    attr_writer :logger

    # Queue name prefix, defaults to "falqon"
    sig { returns(String) }
    def prefix
      @prefix ||= "falqon"
    end

    # Failed message retry strategy
    #
    # @see Falqon::Strategies
    sig { returns(Symbol) }
    def retry_strategy
      @retry_strategy ||= :linear
    end

    # Failed message retry strategy
    #
    # @see Falqon::Strategies
    sig { params(retry_strategy: Symbol).returns(Symbol) }
    def retry_strategy=(retry_strategy)
      raise ArgumentError, "Invalid retry strategy #{retry_strategy.inspect}" unless [:none, :linear].include? retry_strategy

      @retry_strategy = retry_strategy
    end

    # Maximum number of retries before a message is discarded
    #
    # Only applicable when using the +:linear+ retry strategy
    #
    # @see Falqon::Strategies::Linear
    sig { returns(Integer) }
    def max_retries
      @max_retries ||= 3
    end

    # Delay between retries (in seconds)
    #
    # Only applicable when using the +:linear+ retry strategy
    #
    # @see Falqon::Strategies::Linear
    sig { returns(Integer) }
    def retry_delay
      @retry_delay ||= 0
    end

    # Redis connection pool
    sig { returns(ConnectionPool) }
    def redis
      @redis ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(**redis_options) }
    end

    # Redis connection options passed to +Redis.new+
    sig { returns(Hash) }
    def redis_options
      @redis_options ||= {
        url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
        middlewares: [Middlewares::Logger],
      }
    end

    # Logger instance
    sig { returns(Logger) }
    def logger
      @logger ||= Logger.new(File::NULL)
    end
  end
end
