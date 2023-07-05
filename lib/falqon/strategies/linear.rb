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
          retries = r.hincrby("#{queue.name}:stats:#{id}", :retries, 1)

          r.multi do |t|
            if retries < queue.max_retries || queue.max_retries == -1
              queue.logger.debug "Requeuing message #{id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier back to pending queue
              queue.pending.add(id)
            else
              queue.logger.debug "Discarding message #{id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier to dead queue
              queue.dead.add(id)

              # Clear retry count
              t.hdel("#{queue.name}:stats:#{id}", :retries)
            end

            # Remove identifier from processing queue
            t.lrem(queue.processing.name, 0, id)
          end
        end
      end
    end
  end
end
