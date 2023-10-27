# frozen_string_literal: true

module Falqon
  class CLI
    class Delete < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])

        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1

        raise "--head, --tail, --index, and --range are mutually exclusive" if [options[:head], options[:tail], options[:index], options[:range]].count { |o| o } > 1
        raise "--range must be specified as two integers" if options[:range] && options[:range].count != 2

        raise "--id is mutually exclusive with --head, --tail, --index, and --range" if options[:id] && [options[:head], options[:tail], options[:index], options[:range]].count { |o| o }.positive?
      end

      def execute
        # Collect identifiers
        ids = if options[:id]
                Array(options[:id])
              else
                queue.redis.with do |r|
                  if options[:index]
                    Array(options[:index]).map do |i|
                      r.lindex(subqueue.name, i) || raise("No entry at index #{i}")
                    end
                  else
                    r.lrange(subqueue.name, *range_options)
                  end
                end
              end

        # Transform identifiers to entries
        entries = ids.map do |id|
          entry = Falqon::Entry.new(queue, id: id.to_i)

          raise "No entry with ID #{id}" unless entry.exists?

          entry
        end

        # Delete entries
        entries.each(&:delete)

        if options[:pending]
          puts "Deleted #{entries.count} pending entries from queue #{queue.id}"
        elsif options[:processing]
          puts "Deleted #{entries.count} processing entries from queue #{queue.id}"
        elsif options[:dead]
          puts "Deleted #{entries.count} dead entries from queue #{queue.id}"
        else
          puts "Deleted #{entries.count} entries from queue #{queue.id}"
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
