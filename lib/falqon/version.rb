# frozen_string_literal: true

module Falqon
  # @!visibility private
  module Version
    MAJOR = 0
    MINOR = 0
    PATCH = 1
    PRE   = nil

    VERSION = [MAJOR, MINOR, PATCH].compact.join(".")

    STRING = [VERSION, PRE].compact.join("-")
  end

  # @!visibility private
  VERSION = Version::STRING

  # @!visibility private
  PROTOCOL = 1
end
