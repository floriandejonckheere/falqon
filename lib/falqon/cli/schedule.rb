# frozen_string_literal: true

module Falqon
  class CLI
    # Schedule failed messages for a retry
    #
    # This command moves all eligible messages from the scheduled queue back to the head of the pending queue (in order).
    # Messages are eligible for a retry according to the configured retry strategy.
    #
    # Usage:
    #   falqon schedule -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE  # Queue name
    #
    # @example Schedule eligible failed messages for retry
    #   $ falqon schedule --queue jobs
    #   Scheduled 3 messages for a retry in queue jobs
    class Schedule < Falqon::CLI::Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
      end

      # @!visibility private
      def execute
        # Schedule failed messages
        message_ids = queue.schedule

        puts "Scheduled #{pluralize(message_ids.count, 'failed message', 'failed messages')} for a retry in queue #{queue.name}"
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end
    end
  end
end
