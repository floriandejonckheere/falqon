# frozen_string_literal: true

module Falqon
  ##
  # Connection pool that logs method calls
  # @!visibility private
  #
  class ConnectionPoolSnooper < ConnectionPool
    def with(...)
      puts "#{caller(1..1).first[/.*:in/][0..-4]} #{caller(1..1).first[/`.*'/][1..-2]}"

      super
    end
  end
end
