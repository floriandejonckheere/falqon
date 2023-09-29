# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that does not retry
    #
    class None < Strategy
      sig { params(entry: Entry).void }
      def retry(entry)
        # FIXME: use Redis connection of caller
        queue.redis.with do |r|
          r.multi do |t|
            # Kill message immediately
            entry.kill

            # Remove identifier from processing queue
            queue.processing.remove(entry.id)

            # Set entry status
            t.hset("#{queue.name}:metadata:#{entry.id}", :status, "dead")
          end
        end
      end
    end
  end
end
