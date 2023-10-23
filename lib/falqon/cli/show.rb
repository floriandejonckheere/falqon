# frozen_string_literal: true

module Falqon
  class CLI
    class Show < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])

        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1
        raise "--meta and --data are mutually exclusive" if [options[:meta], options[:data]].count(true) > 1

        raise "--head, --tail, --index, and --range are mutually exclusive" if [options[:head], options[:tail], options[:index], options[:range]].count { |o| o } > 1
        raise "--range must be specified as two integers" if options[:range] && options[:range].count != 2

        raise "--id is mutually exclusive with --head, --tail, --index, and --range" if options[:id] && [options[:head], options[:tail], options[:index], options[:range]].count { |o| o }.positive?
      end

      def execute
        start, stop = range_options

        # Collect entries to display
        entries = if options[:id]
                    [options[:id]]
                  else
                    queue.redis.with do |r|
                      r.lrange(subqueue.name, start, stop)
                    end
                  end

        # Serialize entries
        entries.each do |id|
          entry = Falqon::Entry.new(queue, id: id.to_i)

          puts Serializer
            .new(entry, meta: options[:meta], data: options[:data])
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end

      def subqueue
        @subqueue ||= if options[:processing]
                        queue.processing
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
        elsif options[:index]
          [
            options[:index],
            options[:index],
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

      class Serializer
        attr_reader :entry, :meta, :data

        def initialize(entry, meta: false, data: false)
          @entry = entry
          @meta = meta
          @data = data
        end

        def to_s
          return entry.message if data

          if meta
            "id = #{entry.id} " \
              "retries = #{entry.metadata.retries} " \
              "created_at = #{Time.at(entry.metadata.created_at)} " \
              "updated_at = #{Time.at(entry.metadata.updated_at)} " \
              "message = #{entry.message.length} bytes"
          else
            "id = #{entry.id} message = #{entry.message.length} bytes"
          end
        end
      end
    end
  end
end
