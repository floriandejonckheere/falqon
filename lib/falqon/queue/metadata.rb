# frozen_string_literal: true

# typed: strict

module Falqon
  class Queue
    ##
    # Queue metadata storing various statistics and information about a queue
    #
    class Metadata
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

        params.each do |key, value|
          send("#{key}=", value)
        end
      end

      # Parse metadata from Redis hash
      #
      # @!visibility private
      #
      sig { params(data: T::Hash[String, String]).returns(T.attached_class) }
      def self.parse(data)
        # Transform keys to symbols and values to integers
        new data
          .transform_keys(&:to_sym)
          .transform_values(&:to_i)
      end
    end
  end
end
