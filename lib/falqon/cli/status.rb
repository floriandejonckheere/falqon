# frozen_string_literal: true

module Falqon
  class CLI
    class Status < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])

        raise "No queues registered" if Falqon::Queue.all.empty?
      end

      def execute
        queues = options[:queue] ? [Falqon::Queue.new(options[:queue])] : Falqon::Queue.all

        # Left pad queue names to the same length
        length = queues.map(&:id).max.to_s.length

        queues.each do |queue|
          if queue.pending.empty? && queue.processing.empty? && queue.dead.empty?
            puts "#{queue.id.ljust length}: empty"
          else
            puts "#{queue.id.ljust length}: #{queue.pending.size} pending, #{queue.processing.size} processing, #{queue.dead.size} dead"
          end
        end
      end
    end
  end
end
