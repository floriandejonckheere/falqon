# frozen_string_literal: true

module Falqon
  class CLI
    class List < Base
      def validate; end

      def execute
        Falqon::Queue.all.each do |queue|
          puts queue.id
        end
      end
    end
  end
end
