# frozen_string_literal: true

# typed: true

require "forwardable"

require "sorbet-runtime"
require "zeitwerk"

module Falqon
  class << self
    extend Forwardable
    extend T::Sig

    # Code loader instance
    # @!visibility private
    attr_reader :loader

    # Global configuration
    #
    # @see Falqon::Configuration
    sig { returns(Configuration) }
    def configuration
      @configuration ||= Configuration.new
    end

    # @!visibility private
    def root
      @root ||= Pathname.new(File.expand_path(File.join("..", ".."), __FILE__))
    end

    # @!visibility private
    def setup
      @loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)

      # Register inflections
      require root.join("config/inflections.rb")

      # Collapse concerns directory
      loader.collapse(root.join("lib/falqon/concerns"))

      # Configure Rails generators (if applicable)
      if const_defined?(:Rails)
        loader.collapse(root.join("lib/generators"))
      else
        loader.ignore(root.join("lib/generators"))
      end

      loader.setup
      loader.eager_load
    end

    # @!visibility private
    def configure
      yield configuration
    end

    def_delegator :configuration, :redis
    def_delegator :configuration, :logger
  end
end

Falqon.setup
