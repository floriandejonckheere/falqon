# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that retries a fixed number of times
    #
    class Linear < Strategy
      sig { params(id: Identifier).void }
      def retry(id)
        # FIXME: use Redis connection of caller
        queue.redis.with do |r|
          # Increment retry count
          retries = r.incr("#{queue.name}:retries:#{id}")

          r.multi do |t|
            if retries < queue.max_retries
              queue.logger.debug "Requeuing message #{id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier back to queue
              queue.queue.add(id)
            else
              queue.logger.debug "Discarding message #{id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier to dead queue
              queue.dead.add(id)

              # Clear retry count
              t.del("#{queue.name}:retries:#{id}")
            end

            # Remove identifier from processing queue
            t.lrem(queue.processing.name, 0, id)
          end
        end
      end
    end
  end
end
