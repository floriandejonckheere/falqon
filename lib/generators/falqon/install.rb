# frozen_string_literal: true

module Falqon
  class Install < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def create_initializer_file
      create_file "config/initializers/falqon.rb", <<~RUBY
        Falqon.configure do |config|
          # Configure global queue name prefix
          # config.prefix = ENV.fetch("FALQON_PREFIX", "falqon")

          # Retry strategy (none or linear)
          # config.retry_strategy = :linear

          # Maximum number of retries before a message is discarded (-1 for infinite retries)
          # config.max_retries = 3

          # Configure Redis connection pool (defaults to $REDIS_URL)
          # config.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")) }

          # Configure logger
          # config.logger = Logger.new(STDOUT)
        end
      RUBY
    end
  end
end