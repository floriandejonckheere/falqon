# frozen_string_literal: true

module Falqon
  class CLI
    class Status < Base
      def call
        return puts "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])

        queues = options[:queue] ? [Falqon::Queue.new(options[:queue])] : Falqon::Queue.all

        return puts "No queues registered" if queues.empty?

        # Left pad queue names to the same length
        length = queues.map(&:name).max.to_s.length

        queues.each do |queue|
          if queue.empty?
            puts "#{queue.name.ljust length}: empty"
          else
            puts "#{queue.name.ljust length}: #{queue.size} entries (#{queue.pending.size} pending, #{queue.processing.size} processing, #{queue.dead.size} dead)"
          end
        end
      end
    end
  end
end
