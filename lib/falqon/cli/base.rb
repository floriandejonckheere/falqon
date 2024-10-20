# frozen_string_literal: true

module Falqon
  class CLI
    # @!visibility private
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def call
        validate
        execute
      rescue StandardError => e
        puts e.message
      end

      protected

      def validate
        raise NotImplementedError
      end

      def execute
        raise NotImplementedError
      end

      def pluralize(count, singular, plural)
        "#{count} #{count == 1 ? singular : plural}"
      end
    end
  end
end
