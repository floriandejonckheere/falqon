# frozen_string_literal: true

# typed: true

require "logger"

require "redis"
require "connection_pool"

module Falqon
  class Configuration
    extend T::Sig

    DEFAULT_PREFIX = "falqon"

    # Queue name prefix
    sig { params(prefix: String).returns(String) }
    attr_writer :prefix

    # Redis connection pool
    sig { params(redis: ConnectionPool).returns(ConnectionPool) }
    attr_writer :redis

    # Logger instance
    sig { params(logger: Logger).returns(Logger) }
    attr_writer :logger

    sig { returns(String) }
    def prefix
      @prefix ||= DEFAULT_PREFIX
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
