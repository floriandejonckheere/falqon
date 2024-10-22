# frozen_string_literal: true

module Falqon
  class CLI
    # Display queue status
    #
    # Usage:
    #   falqon status
    #
    # Options:
    #   -q, [--queue=QUEUE]  # Queue name
    #
    # @example Print status of all queues
    #   $ falqon status
    #   jobs: 41 messages (34 pending, 2 processing, 0 scheduled, 5 dead)
    # emails: empty
    #
    # @example Print status of a specific queue
    #   $ falqon status --queue jobs
    #   jobs: 41 messages (34 pending, 2 processing, 0 scheduled, 5 dead)
    #
    class Status < Base
      # @!visibility private
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "No queues registered" if Falqon::Queue.all.empty?
      end

      # @!visibility private
      def execute
        queues = options[:queue] ? [Falqon::Queue.new(options[:queue])] : Falqon::Queue.all

        # Left pad queue names to the same length
        length = queues.map { |q| q.name.length }.max

        queues.each do |queue|
          if queue.pending.empty? && queue.processing.empty? && queue.dead.empty?
            puts "#{queue.name.ljust length}: empty"
          else
            puts "#{queue.name.ljust length}: #{queue.pending.size} pending, #{queue.processing.size} processing, #{queue.scheduled.size} scheduled, #{queue.dead.size} dead"
          end
        end
      end
    end
  end
end
