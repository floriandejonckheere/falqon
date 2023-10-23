# frozen_string_literal: true

module Falqon
  class CLI
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
    end
  end
end
