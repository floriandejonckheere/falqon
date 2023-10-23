# frozen_string_literal: true

module Falqon
  class CLI
    class Version < Base
      def validate; end

      def execute
        puts "Falqon #{Falqon::VERSION}"
      end
    end
  end
end
