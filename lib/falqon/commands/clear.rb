# frozen_string_literal: true

module Falqon
  module Commands
    # Clear messages from a queue
    #
    # Clearing a subqueue removes all messages and their data from the subqueue.
    #
    # Usage:
    #   falqon clear -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE                                           # Queue name
    #       [--pending], [--no-pending], [--skip-pending]           # Clear only pending messages
    #       [--processing], [--no-processing], [--skip-processing]  # Clear only processing messages
    #       [--dead], [--no-dead], [--skip-dead]                    # Clear only dead messages
    #
    # If none of the +--pending+, +--processing+, +--scheduled+, or +--dead+ options are specified, all messages are cleared.
    #
    # @example Clear all messages in a queue
    #   $ falqon clear --queue jobs
    #   Cleared 3 messages from queue jobs
    #
    # @example Clear only pending messages
    #   $ falqon clear --queue jobs --pending
    #   Cleared 3 messages from queue jobs
    #
    # @example Clear only processing messages
    #   $ falqon clear --queue jobs --processing
    #   Cleared 3 messages from queue jobs
    #
    # @example Clear only scheduled messages
    #   $ falqon clear --queue jobs --scheduled
    #   Cleared 3 messages from queue jobs
    #
    # @example Clear only dead messages
    #   $ falqon clear --queue jobs --dead
    #   Cleared 3 messages from queue jobs
    #
    class Clear < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
        raise "--pending, --processing, --scheduled, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:scheduled], options[:dead]].count(true) > 1
      end

      # @!visibility private
      def execute
        # Clear messages
        ids = subqueue.clear

        if options[:pending]
          puts "Cleared #{pluralize(ids.count, 'pending message', 'pending messages')} from queue #{queue.name}"
        elsif options[:processing]
          puts "Cleared #{pluralize(ids.count, 'processing message', 'processing messages')} from queue #{queue.name}"
        elsif options[:scheduled]
          puts "Cleared #{pluralize(ids.count, 'scheduled message', 'scheduled messages')} from queue #{queue.name}"
        elsif options[:dead]
          puts "Cleared #{pluralize(ids.count, 'dead message', 'dead messages')} from queue #{queue.name}"
        else
          puts "Cleared #{pluralize(ids.count, 'message', 'messages')} from queue #{queue.name}"
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end

      def subqueue
        @subqueue ||= if options[:pending]
                        queue.pending
                      elsif options[:processing]
                        queue.processing
                      elsif options[:scheduled]
                        queue.scheduled
                      elsif options[:dead]
                        queue.dead
                      else
                        queue
                      end
      end
    end
  end
end
