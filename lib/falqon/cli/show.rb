# frozen_string_literal: true

module Falqon
  class CLI
    # Display messages in a queue
    #
    # Usage:
    #   falqon show -q, --queue=QUEUE
    #
    # Options:
    #   -q, --queue=QUEUE                                           # Queue name
    #       [--pending], [--no-pending], [--skip-pending]           # Display pending messages (default)
    #       [--processing], [--no-processing], [--skip-processing]  # Display processing messages
    #       [--dead], [--no-dead], [--skip-dead]                    # Display dead messages
    #   -d, [--data], [--no-data], [--skip-data]                    # Display raw data
    #   -m, [--meta], [--no-meta], [--skip-meta]                    # Display additional metadata
    #       [--head=N]                                              # Display N messages from head of queue
    #       [--tail=N]                                              # Display N messages from tail of queue
    #       [--index=N]                                             # Display message at index N
    #       [--range=N M]                                           # Display messages at index N to M
    #       [--id=N]                                                # Display message with ID N
    #
    # @example Print all messages in the queue (by default only pending messages are displayed)
    #   $ falqon show --queue jobs
    #   id = 1 data = 8742 bytes
    #
    # @example Display only pending messages
    #   $ falqon show --queue jobs --pending
    #   ...
    #
    # @example Display only processing messages
    #   $ falqon show --queue jobs --processing
    #   ...
    #
    # @example Display only scheduled messages
    #   $ falqon show --queue jobs --scheduled
    #   ...
    #
    # @example Display only dead messages
    #   $ falqon show --queue jobs --dead
    #   ...
    #
    # @example Display raw data
    #   $ falqon show --queue jobs --data
    #   {"id":1,"message":"Hello, world!"}
    #
    # @example Display additional metadata
    #   $ falqon show --queue jobs --meta
    #   id = 1 retries = 0 created_at = 1970-01-01 00:00:00 +0000 updated_at = 1970-01-01 00:00:00 +0000 data = 8742 bytes
    #
    # @example Display first 5 messages
    #   $ falqon show --queue jobs --head 5
    #   id = 1 data = 8742 bytes
    #   id = 2 data = 8742 bytes
    #   id = 3 data = 8742 bytes
    #   id = 4 data = 8742 bytes
    #   id = 5 data = 8742 bytes
    #
    # @example Display last 5 messages
    #   $ falqon show --queue jobs --tail 5
    #   ...
    #
    # @example Display message at index 5
    #   $ falqon show --queue jobs --index 3 --index 5
    #   id = 3 data = 8742 bytes
    #   id = 5 data = 8742 bytes
    #
    # @example Display messages from index 5 to 10
    #   $ falqon show --queue jobs --range 5 10
    #   ...
    #
    # @example Display message with ID 5
    #   $ falqon show --queue jobs --id 5 --id 1
    #   id = 5 data = 8742 bytes
    #   id = 1 data = 8742 bytes
    #
    class Show < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "--pending, --processing, --scheduled, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:scheduled], options[:dead]].count(true) > 1
        raise "--meta and --data are mutually exclusive" if [options[:meta], options[:data]].count(true) > 1

        raise "--head, --tail, --index, and --range are mutually exclusive" if [options[:head], options[:tail], options[:index], options[:range]].count { |o| o } > 1
        raise "--range must be specified as two integers" if options[:range] && options[:range].count != 2

        raise "--id is mutually exclusive with --head, --tail, --index, and --range" if options[:id] && [options[:head], options[:tail], options[:index], options[:range]].count { |o| o }.positive?
      end

      # @!visibility private
      def execute
        # Collect identifiers
        ids = if options[:id]
                Array(options[:id])
              else
                queue.redis.with do |r|
                  if options[:index]
                    Array(options[:index]).map do |i|
                      r.lindex(subqueue.id, i) || raise("No message at index #{i}")
                    end
                  else
                    r.lrange(subqueue.id, *range_options)
                  end
                end
              end

        # Transform identifiers to messages
        messages = ids.map do |id|
          message = Falqon::Message.new(queue, id: id.to_i)

          raise "No message with ID #{id}" unless message.exists?

          message
        end

        # Serialize messages
        messages.each do |message|
          puts Serializer
            .new(message, meta: options[:meta], data: options[:data])
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
                      else
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

      # @!visibility private
      class Serializer
        attr_reader :message, :meta, :data

        def initialize(message, meta: false, data: false)
          @message = message
          @meta = meta
          @data = data
        end

        def to_s
          return message.data if data

          if meta
            "id = #{message.id} " \
              "retries = #{message.metadata.retries} " \
              "retried_at = #{message.metadata.retried_at ? Time.at(message.metadata.retried_at) : 'N/A'} " \
              "retry_error = #{message.metadata.retry_error || 'N/A'} " \
              "created_at = #{Time.at(message.metadata.created_at)} " \
              "updated_at = #{Time.at(message.metadata.updated_at)} " \
              "data = #{message.data.length} bytes"
          else
            "id = #{message.id} data = #{message.data.length} bytes"
          end
        end
      end
    end
  end
end
