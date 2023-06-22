# frozen_string_literal: true

require "connection_pool"
require "redis"
require "zeitwerk"

module Falqon
  class << self
    # Code loader instance
    attr_reader :loader

    # Redis connection pool
    attr_writer :redis

    def redis
      @redis ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }
    end

    def root
      @root ||= Pathname.new(File.expand_path(File.join("..", ".."), __FILE__))
    end

    def setup
      @loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)

      # Register inflections
      require root.join("config/inflections.rb")

      loader.setup
      loader.eager_load
    end

    alias configure instance_eval
  end
end

Falqon.setup
