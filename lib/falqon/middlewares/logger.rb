# frozen_string_literal: true

module Falqon
  # @!visibility private
  module Middlewares
    ##
    # Redis client logger middleware
    # @!visibility private
    #
    module Logger
      def connect(redis_config)
        Falqon.logger.warn { "[redis] #{redis_config.inspect}" }

        super
      end

      def call(command, redis_config)
        Falqon.logger.warn { "[redis] #{command.join(' ')}" }

        super
      end

      def call_pipelined(commands, redis_config)
        Falqon.logger.warn { "[redis] #{commands.join(' ')}" }

        super
      end
    end
  end
end

RedisClient.register(Falqon::Middlewares::Logger)
