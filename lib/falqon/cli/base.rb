# frozen_string_literal: true

module Falqon
  class CLI
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def call
        raise NotImplementedError
      end
    end
  end
end
