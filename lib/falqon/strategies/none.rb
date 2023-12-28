# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that does not retry
    #
    class None < Strategy
      sig { params(message: Message).void }
      def retry(message)
        queue.redis.with do |r|
          r.multi do |t|
            # Kill message immediately
            message.kill

            # Remove identifier from processing queue
            queue.processing.remove(message.id)

            # Set message status
            t.hset("#{queue.id}:metadata:#{message.id}", :status, "dead")
          end
        end
      end
    end
  end
end
