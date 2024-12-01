# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that does not retry
    #
    # When a message fails to process, it is immediately marked as dead and moved to the dead subqueue.
    #
    # @example
    #  queue = Falqon::Queue.new("my_queue", retry_strategy: :none)
    #  queue.push("Hello, World!")
    #  queue.pop { raise Falqon::Error }
    #  queue.inspect # => #<Falqon::Queue name="my_queue" pending=0 processing=0 scheduled=0 dead=1>
    #
    class None < Strategy
      # @!visibility private
      sig { params(message: Message, error: Error).void }
      def retry(message, error)
        queue.redis.with do |r|
          r.multi do |t|
            # Set error metadata
            t.hset(
              "#{queue.id}:metadata:#{message.id}",
              :retried_at, Time.now.to_i,
              :retry_error, error.message,
            )

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
