# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that retries a fixed number of times
    #
    class Linear < Strategy
      sig { params(message: Message).void }
      def retry(message)
        # FIXME: use Redis connection of caller
        queue.redis.with do |r|
          # Increment retry count
          retries = r.hincrby("#{queue.id}:metadata:#{message.id}", :retries, 1)

          r.multi do |t|
            if retries < queue.max_retries || queue.max_retries == -1
              queue.logger.debug "Requeuing message #{message.id} on queue #{queue.name} (attempt #{retries})"

              # Add identifier back to pending queue
              queue.pending.add(message.id)

              # Set message status
              t.hset("#{queue.id}:metadata:#{message.id}", :status, "pending")
            else
              # Kill message after max retries
              message.kill

              # Set message status
              t.hset("#{queue.id}:metadata:#{message.id}", :status, "dead")
            end

            # Remove identifier from processing queue
            queue.processing.remove(message.id)
          end
        end
      end
    end
  end
end
