# frozen_string_literal: true

module Falqon
  class CLI
    class Version < Base
      def call
        puts "Falqon #{Falqon::VERSION}"
      end
    end
  end
end
