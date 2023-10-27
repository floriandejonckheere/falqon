# frozen_string_literal: true

module Falqon
  class CLI
    class Clear < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])
        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1
      end

      def execute
        if options[:pending]
          ids = queue.pending.clear

          puts "Cleared #{pluralize(ids.count, 'pending entry', 'pending entries')} from queue #{queue.id}"
        elsif options[:processing]
          ids = queue.processing.clear

          puts "Cleared #{pluralize(ids.count, 'processing entry', 'processing entries')} from queue #{queue.id}"
        elsif options[:dead]
          ids = queue.dead.clear

          puts "Cleared #{pluralize(ids.count, 'dead entry', 'dead entries')} from queue #{queue.id}"
        else
          ids = queue.clear

          puts "Cleared #{pluralize(ids.count, 'entry', 'entries')} from queue #{queue.id}"
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end
    end
  end
end
