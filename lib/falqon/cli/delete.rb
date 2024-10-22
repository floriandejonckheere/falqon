# frozen_string_literal: true

module Falqon
  class CLI
    # Delete messages from a queue
    #
    # Deleting a message removes it including its data from the queue.
    #
    # Usage:
    #   falqon delete -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE                                           # Queue name
    #       [--pending], [--no-pending], [--skip-pending]           # Delete only pending messages (default)
    #       [--processing], [--no-processing], [--skip-processing]  # Delete only processing messages
    #       [--dead], [--no-dead], [--skip-dead]                    # Delete only dead messages
    #       [--head=N]                                              # Delete N messages from head of queue
    #       [--tail=N]                                              # Delete N messages from tail of queue
    #       [--index=N]                                             # Delete message at index N
    #       [--range=N M]                                           # Delete messages at index N to M
    #       [--id=N]                                                # Delete message with ID N
    #
    # @example Delete all messages in the queue (by default only pending messages are deleted)
    #   $ falqon delete --queue jobs
    #   Deleted 10 messages from queue jobs
    #
    # @example Delete only pending messages
    #   $ falqon delete --queue jobs --pending
    #   Deleted 10 pending messages from queue jobs
    #
    # @example Delete only processing messages
    #   $ falqon delete --queue jobs --processing
    #   Deleted 1 processing message from queue jobs
    #
    # @example Delete only scheduled messages
    #   $ falqon delete --queue jobs --scheduled
    #   Deleted 1 scheduled message from queue jobs
    #
    # @example Delete only dead messages
    #   $ falqon delete --queue jobs --dead
    #   Deleted 5 dead messages from queue jobs
    #
    # @example Delete first 5 messages
    #   $ falqon delete --queue jobs --head 5
    #   Deleted 5 messages from queue jobs
    #
    # @example Delete last 5 messages
    #   $ falqon delete --queue jobs --tail 5
    #   Deleted 5 messages from queue jobs
    #
    # @example Delete message at index 5
    #   $ falqon delete --queue jobs --index 3 --index 5
    #   Deleted 1 message from queue jobs
    #
    # @example Delete messages from index 5 to 10
    #   $ falqon delete --queue jobs --range 5 10
    #   Deleted 6 messages from queue jobs
    #
    # @example Delete message with ID 5
    #   $ falqon delete --queue jobs --id 5 --id 1
    #   Deleted 2 messages from queue jobs
    #
    class Delete < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "--pending, --processing, --scheduled, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:scheduled], options[:dead]].count(true) > 1

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

        # Delete messages
        messages.each(&:delete)

        if options[:processing]
          puts "Deleted #{pluralize(messages.count, 'processing message', 'processing messages')} from queue #{queue.name}"
        elsif options[:scheduled]
          puts "Deleted #{pluralize(messages.count, 'scheduled message', 'scheduled messages')} from queue #{queue.name}"
        elsif options[:dead]
          puts "Deleted #{pluralize(messages.count, 'dead message', 'dead messages')} from queue #{queue.name}"
        else # options[:pending]
          puts "Deleted #{pluralize(messages.count, 'pending message', 'pending messages')} from queue #{queue.name}"
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
                      elsif options[:dead]
                        queue.dead
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
