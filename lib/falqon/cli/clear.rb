# frozen_string_literal: true

module Falqon
  class CLI
    class Clear < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])
        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1
      end

      def execute
        queue = Falqon::Queue.new(options[:queue])

        if options[:pending]
          ids = queue.pending.clear

          puts "Cleared #{ids.count} pending entries from queue #{queue.id}"
        elsif options[:processing]
          ids = queue.processing.clear

          puts "Cleared #{ids.count} processing entries from queue #{queue.id}"
        elsif options[:dead]
          ids = queue.dead.clear

          puts "Cleared #{ids.count} dead entries from queue #{queue.id}"
        else
          ids = queue.clear

          puts "Cleared #{ids.count} entries from queue #{queue.id}"
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end
    end
  end
end
