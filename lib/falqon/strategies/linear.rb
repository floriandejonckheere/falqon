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
        queue.redis.with do |r|
          # Increment retry count
          retries = r.hincrby("#{queue.id}:metadata:#{message.id}", :retries, 1)

          r.multi do |t|
            if retries < queue.max_retries || queue.max_retries == -1
              if queue.retry_delay.positive?
                queue.logger.debug "Scheduling message #{message.id} on queue #{queue.name} in #{queue.retry_delay} seconds (attempt #{retries})"

                # Add identifier to scheduled queue
                queue.scheduled.add(message.id, Time.now.to_i + queue.retry_delay)

                # Set message status
                t.hset("#{queue.id}:metadata:#{message.id}", :status, "scheduled")
              else
                queue.logger.debug "Requeuing message #{message.id} on queue #{queue.name} (attempt #{retries})"

                # Add identifier back to pending queue
                queue.pending.add(message.id)

                # Set message status
                t.hset("#{queue.id}:metadata:#{message.id}", :status, "pending")
              end
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
