# frozen_string_literal: true

require "thor"

module Falqon
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "Print version"
    def version
      puts "Falqon #{Falqon::VERSION}"
    end
  end
end
