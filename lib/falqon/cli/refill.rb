# frozen_string_literal: true

module Falqon
  class CLI
    # @!visibility private
    class Refill < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
      end

      def execute
        queue = Falqon::Queue.new(options[:queue])

        ids = queue.refill

        puts "Refilled #{pluralize(ids.count, 'message', 'messages')} in queue #{queue.name}"
      end
    end
  end
end
