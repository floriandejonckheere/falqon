# frozen_string_literal: true

# typed: strict

module Falqon
  class Queue
    ##
    # Queue metadata storing various statistics and information about a queue
    #
    class Metadata < Falqon::Metadata
      extend T::Sig
      include T::Props

      # Total number of messages processed
      prop :processed, Integer

      # Total number of messages failed
      prop :failed, Integer

      # Total number of messages retried
      prop :retried, Integer

      # Timestamp of creation
      prop :created_at, Integer

      # Timestamp of last update
      prop :updated_at, Integer

      # Protocol version
      prop :version, Integer

      # Create a Metadata object
      sig { params(params: T::Hash[Symbol, T.untyped]).void }
      def initialize(params = {})
        @processed = T.let(0, Integer)
        @failed = T.let(0, Integer)
        @retried = T.let(0, Integer)

        super
      end
    end
  end
end
