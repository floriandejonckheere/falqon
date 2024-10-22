# frozen_string_literal: true

module Falqon
  class CLI
    # Kill messages in a queue
    #
    # Killing a message removes it from the pending or scheduled queue, and moves it to the dead queue.
    #
    # Usage:
    #   falqon kill -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE                                           # Queue name
    #       [--pending], [--no-pending], [--skip-pending]           # Kill only pending messages (default)
    #       [--processing], [--no-processing], [--skip-processing]  # Kill only processing messages
    #       [--head=N]                                              # Kill N messages from head of queue
    #       [--tail=N]                                              # Kill N messages from tail of queue
    #       [--index=N]                                             # Kill message at index N
    #       [--range=N M]                                           # Kill messages at index N to M
    #       [--id=N]                                                # Kill message with ID N
    #
    # @example Kill all messages in the queue (by default only pending messages are killed)
    #   $ falqon kill --queue jobs
    #   Killed 10 messages from queue jobs
    #
    # @example Kill only pending messages
    #   $ falqon kill --queue jobs --pending
    #   Killed 10 pending messages from queue jobs
    #
    # @example Kill only processing messages
    #   $ falqon kill --queue jobs --processing
    #   Killed 1 processing message from queue jobs
    #
    # @example Kill only scheduled messages
    #   $ falqon kill --queue jobs --scheduled
    #   Killed 1 scheduled message from queue jobs
    #
    # @example Kill first 5 messages
    #   $ falqon kill --queue jobs --head 5
    #   Killed 5 messages from queue jobs
    #
    # @example Kill last 5 messages
    #   $ falqon kill --queue jobs --tail 5
    #   Killed 5 messages from queue jobs
    #
    # @example Kill message at index 5
    #   $ falqon kill --queue jobs --index 3 --index 5
    #   Killed 1 message from queue jobs
    #
    # @example Kill messages from index 5 to 10
    #   $ falqon kill --queue jobs --range 5 10
    #   Killed 6 messages from queue jobs
    #
    # @example Kill message with ID 5
    #   $ falqon kill --queue jobs --id 5 --id 1
    #   Killed 2 messages from queue jobs
    #
    class Kill < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "--pending, --scheduled, and --processing are mutually exclusive" if [options[:pending], options[:scheduled], options[:processing]].count(true) > 1

        raise "--head, --tail, --index, and --range are mutually exclusive" if [options[:head], options[:tail], options[:index], options[:range]].count { |o| o } > 1
        raise "--range must be specified as two integers" if options[:range] && options[:range].count != 2

        raise "--id is mutually exclusive with --head, --tail, --index, and --range" if options[:id] && [options[:head], options[:tail], options[:index], options[:range]].count { |o| o }.positive?
      end

      # @!visibility private
      def execute
        # Collect identifiers
        ids = if options[:id]
                Array(options[:id])
              elsif options[:index]
                Array(options[:index]).map do |i|
                  subqueue.peek(index: i) || raise("No message at index #{i}")
                end
              else
                start, stop = range_options

                subqueue.range(start:, stop:).map(&:to_i)
              end

        # Transform identifiers to messages
        messages = ids.map do |id|
          message = Falqon::Message.new(queue, id: id.to_i)

          raise "No message with ID #{id}" unless message.exists?

          message
        end

        # Kill messages
        messages.each(&:kill)

        if options[:processing]
          puts "Killed #{pluralize(messages.count, 'processing message', 'processing messages')} in queue #{queue.name}"
        elsif options[:scheduled]
          puts "Killed #{pluralize(messages.count, 'scheduled message', 'scheduled messages')} in queue #{queue.name}"
        else # options[:pending]
          puts "Killed #{pluralize(messages.count, 'pending message', 'pending messages')} in queue #{queue.name}"
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end

      def subqueue
        @subqueue ||= if options[:processing]
                        queue.processing
                      elsif options[:scheduled]
                        queue.scheduled
                      else # options[:pending]
                        queue.pending
                      end
      end

      def range_options
        if options[:tail]
          [
            -options[:tail],
            -1,
          ]
        elsif options[:range]
          [
            options[:range].first,
            options[:range].last,
          ]
        else # options[:head]
          [
            0,
            options.fetch(:head, 0) - 1,
          ]
        end
      end
    end
  end
end
