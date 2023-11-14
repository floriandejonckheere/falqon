# frozen_string_literal: true

require "date"

module Falqon
  class CLI
    class Stats < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:name).include?(options[:queue])

        raise "No queues registered" if Falqon::Queue.all.empty?
      end

      def execute
        queues = options[:queue] ? [Falqon::Queue.new(options[:queue])] : Falqon::Queue.all

        # Left pad queue names to the same length
        length = queues.map { |q| q.name.length }.max

        queues.each do |queue|
          puts "#{queue.name.ljust length}: #{queue.metadata.processed} processed, #{queue.metadata.failed} failed, #{queue.metadata.retried} retried (created: #{Time.at(queue.metadata.created_at).to_datetime.iso8601}, updated: #{Time.at(queue.metadata.updated_at).to_datetime.iso8601})"
        end
      end
    end
  end
end
