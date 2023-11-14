# frozen_string_literal: true

module Falqon
  class CLI
    class Clear < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1
      end

      def execute
        # Clear messages
        ids = subqueue.clear

        if options[:pending]
          puts "Cleared #{pluralize(ids.count, 'pending message', 'pending messages')} from queue #{queue.name}"
        elsif options[:processing]
          puts "Cleared #{pluralize(ids.count, 'processing message', 'processing messages')} from queue #{queue.name}"
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
                      elsif options[:dead]
                        queue.dead
                      else
                        queue
                      end
      end
    end
  end
end
