# frozen_string_literal: true

module Falqon
  class CLI
    # Refill queue (move processing messages to pending)
    #
    # This command moves all messages from the processing queue back to the pending queue (in order).
    # It is useful when a worker crashes or is stopped, and messages are left in the processing queue.
    #
    # Usage:
    #   falqon refill -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE  # Queue name
    #
    # @example Refill the queue
    #   $ falqon refill --queue jobs
    #   Refilled 3 messages in queue jobs
    #
    class Refill < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
      end

      # @!visibility private
      def execute
        queue = Falqon::Queue.new(options[:queue])

        ids = queue.refill

        puts "Refilled #{pluralize(ids.count, 'message', 'messages')} in queue #{queue.name}"
      end
    end
  end
end
