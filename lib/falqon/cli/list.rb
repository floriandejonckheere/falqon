# frozen_string_literal: true

module Falqon
  class CLI
    # Display all active (registered) queues
    #
    # Usage:
    #  falqon list
    #
    # @example
    #   $ falqon list
    #   jobs
    #   emails
    class List < Base
      # @!visibility private
      def validate; end

      # @!visibility private
      def execute
        Falqon::Queue.all.each do |queue|
          puts queue.name
        end
      end
    end
  end
end
