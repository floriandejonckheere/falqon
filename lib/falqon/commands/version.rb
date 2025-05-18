# frozen_string_literal: true

module Falqon
  module Commands
    # @!visibility private
    class Version < Base
      def validate; end

      def execute
        puts "Falqon #{Falqon::VERSION}"
      end
    end
  end
end
