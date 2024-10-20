# frozen_string_literal: true

module Falqon
  class CLI
    class Schedule < Falqon::CLI::Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])
      end

      def execute
        # Schedule failed messages
        message_ids = queue.schedule
        puts queue.inspect
        puts queue.retry_delay
        puts "Scheduled #{pluralize(message_ids.count, 'failed message', 'failed messages')} for a retry"
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end
    end
  end
end
