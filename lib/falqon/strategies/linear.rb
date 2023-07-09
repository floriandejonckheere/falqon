# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that retries a fixed number of times
    #
    class Linear < Strategy
      sig { params(entry: Entry).void }
      def retry(entry)
        # FIXME: use Redis connection of caller
        queue.redis.with do |r|
          # Increment retry count
          retries = r.hincrby("#{queue.name}:stats:#{entry.id}", :retries, 1)

          r.multi do |_t|
            if retries < queue.max_retries || queue.max_retries == -1
              queue.logger.debug "Requeuing message #{entry.id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier back to pending queue
              queue.pending.add(entry.id)
            else
              # Kill message after max retries
              entry.kill
            end

            # Remove identifier from processing queue
            queue.processing.remove(entry.id)
          end
        end
      end
    end
  end
end
