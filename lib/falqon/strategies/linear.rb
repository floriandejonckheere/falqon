# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that retries a fixed number of times
    #
    # When a message fails to process, it is moved to the scheduled queue, and retried after a fixed delay (configured by {Falqon::Queue#retry_delay}).
    # If a messages fails to process after the maximum number of retries (configured by {Falqon::Queue#max_retries}), it is marked as dead, and moved to the dead subqueue.
    #
    # When using the linear strategy and the retry delay is set to a non-zero value, a scheduled needs to be started to retry the messages after the configured delay.
    #
    #  queue = Falqon::Queue.new("my_queue")
    #
    #  # Start the watcher in a separate thread
    #  Thread.new { loop { queue.schedule; sleep 1 } }
    #
    #  # Or start the watcher in a separate fiber
    #  Fiber
    #    .new { loop { queue.schedule; sleep 1 } }
    #    .resume
    #
    # @example
    #  queue = Falqon::Queue.new("my_queue", retry_strategy: :linear, retry_delay: 60, max_retries: 3)
    #  queue.push("Hello, World!")
    #  queue.pop { raise Falqon::Error }
    #  queue.inspect # => #<Falqon::Queue name="my_queue" pending=0 processing=0 scheduled=1 dead=0>
    #  sleep 60
    #  queue.pop # => "Hello, World!"
    #
    class Linear < Strategy
      # @!visibility private
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
