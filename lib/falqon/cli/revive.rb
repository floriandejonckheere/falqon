# frozen_string_literal: true

module Falqon
  class CLI
    class Revive < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])
      end

      def execute
        queue = Falqon::Queue.new(options[:queue])

        ids = queue.revive

        puts "Revived #{pluralize(ids.count, 'message', 'messages')} in queue #{queue.id}"
      end
    end
  end
end
