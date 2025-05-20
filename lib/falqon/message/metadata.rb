# frozen_string_literal: true

# typed: strict

module Falqon
  class Message
    ##
    # Message metadata storing various statistics and information about a message
    #
    class Metadata < Falqon::Metadata
      extend T::Sig
      include T::Props

      # Status (unknown, pending, processing, scheduled, dead)
      prop :status, String

      # Number of times the message has been retried
      prop :retries, Integer

      # Timestamp of last retry
      prop :retried_at, T.nilable(Integer)

      # Last error message
      prop :retry_error, T.nilable(String)

      # Timestamp of creation
      prop :created_at, Integer

      # Timestamp of last update
      prop :updated_at, Integer

      # Create a Metadata object
      sig { params(params: T::Hash[Symbol, T.untyped]).void }
      def initialize(params = {})
        self.status = "unknown"
        self.retries = 0

        super
      end
    end
  end
end
