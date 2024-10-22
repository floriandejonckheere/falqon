# frozen_string_literal: true

module Falqon
  class CLI
    # Revive queue (move dead messages to pending)
    #
    # This command moves all messages from the dead queue back to the pending queue (in order).
    # It is useful when messages are moved to the dead queue due to repeated failures, and need to be retried.
    #
    # Usage:
    #   falqon revive -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE  # Queue name
    #
    # @example Revive the queue
    #   $ falqon revive --queue jobs
    #   Revived 3 messages in queue jobs
    #
    class Revive < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
      end

      # @!visibility private
      def execute
        queue = Falqon::Queue.new(options[:queue])

        ids = queue.revive

        puts "Revived #{pluralize(ids.count, 'message', 'messages')} in queue #{queue.name}"
      end
    end
  end
end
