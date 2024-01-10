# frozen_string_literal: true

# typed: true

require "logger"

require "redis"
require "connection_pool"

module Falqon
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

    # Logger instance
    sig { params(logger: Logger).returns(Logger) }
    attr_writer :logger

    sig { returns(String) }
    def prefix
      @prefix ||= "falqon"
    end

    sig { returns(Symbol) }
    def retry_strategy
      @retry_strategy ||= :linear
    end

    sig { params(retry_strategy: Symbol).returns(Symbol) }
    def retry_strategy=(retry_strategy)
      raise ArgumentError, "Invalid retry strategy #{retry_strategy.inspect}" unless [:none, :linear].include? retry_strategy

      @retry_strategy = retry_strategy
    end

    sig { returns(Integer) }
    def max_retries
      @max_retries ||= 3
    end

    sig { returns(Integer) }
    def retry_delay
      @retry_delay ||= 0
    end

    sig { returns(ConnectionPool) }
    def redis
      @redis ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }
    end

    sig { returns(Logger) }
    def logger
      @logger ||= Logger.new(File::NULL)
    end
  end
end
