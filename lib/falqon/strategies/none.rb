# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that does not retry
    #
    class None < Strategy
      sig { params(id: Identifier).void }
      def retry(id)
        queue.logger.debug "Discarding message #{id} on queue #{queue.name}"

        # FIXME: use Redis connection of caller
        queue.redis.with do |r|
          # Add identifier to dead queue
          queue.dead.add(id)

          # Remove identifier from processing queue
          r.lrem(queue.processing.name, 0, id)
        end
      end
    end
  end
end
