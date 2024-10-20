# frozen_string_literal: true

module Falqon
  class CLI
    # @!visibility private
    class Kill < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "--pending, --scheduled, and --processing are mutually exclusive" if [options[:pending], options[:scheduled], options[:processing]].count(true) > 1

        raise "--head, --tail, --index, and --range are mutually exclusive" if [options[:head], options[:tail], options[:index], options[:range]].count { |o| o } > 1
        raise "--range must be specified as two integers" if options[:range] && options[:range].count != 2

        raise "--id is mutually exclusive with --head, --tail, --index, and --range" if options[:id] && [options[:head], options[:tail], options[:index], options[:range]].count { |o| o }.positive?
      end

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
