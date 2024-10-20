# frozen_string_literal: true

module Falqon
  # Base error class for Falqon
  #
  class Error < StandardError
  end

  # Error raised when a version mismatch is detected
  #
  class VersionMismatchError < Error
  end
end
