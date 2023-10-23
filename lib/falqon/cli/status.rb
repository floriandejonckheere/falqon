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
          puts "#{queue.name.ljust length}: #{queue.size} entries"
        end
      end
    end
  end
end
