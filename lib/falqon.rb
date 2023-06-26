# frozen_string_literal: true

require "forwardable"

require "sorbet-runtime"
require "zeitwerk"

module Falqon
  class << self
    extend Forwardable

    # Code loader instance
    attr_reader :loader

    def configuration
      @configuration ||= Configuration.new
    end

    def root
      @root ||= Pathname.new(File.expand_path(File.join("..", ".."), __FILE__))
    end

    def setup
      @loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)

      # Register inflections
      require root.join("config/inflections.rb")

      loader.setup
      loader.eager_load
    end

    def configure
      yield configuration
    end

    def_delegator :configuration, :redis
    def_delegator :configuration, :logger
  end
end

Falqon.setup
