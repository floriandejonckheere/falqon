# frozen_string_literal: true

# typed: strict

module Falqon
  class Queue
    ##
    # Queue metadata storing various statistics and information about a queue
    #
    class Metadata < Falqon::Metadata
      extend T::Sig

      # Total number of messages processed
      sig { returns(Integer) }
      attr_reader :processed

      sig { params(value: T.any(String, Integer)).void }
      def processed=(value)
        @processed = value.to_i
      end

      # Total number of messages failed
      sig { returns(Integer) }
      attr_reader :failed

      sig { params(value: T.any(String, Integer)).void }
      def failed=(value)
        @failed = value.to_i
      end

      # Total number of messages retried
      sig { returns(Integer) }
      attr_reader :retried

      sig { params(value: T.any(String, Integer)).void }
      def retried=(value)
        @retried = value.to_i
      end

      # Timestamp of creation
      sig { returns(T.nilable(Integer)) }
      attr_reader :created_at

      sig { params(value: T.nilable(T.any(String, Integer))).void }
      def created_at=(value)
        @created_at = value&.to_i
      end

      # Timestamp of last update
      sig { returns(T.nilable(Integer)) }
      attr_reader :updated_at

      sig { params(value: T.nilable(T.any(String, Integer))).void }
      def updated_at=(value)
        @updated_at = value&.to_i
      end

      # Protocol version
      sig { returns(T.nilable(Integer)) }
      attr_reader :version

      sig { params(value: T.nilable(T.any(String, Integer))).void }
      def version=(value)
        @version = value&.to_i
      end

      # @!visibility private
      sig { params(params: T::Hash[Symbol, T.untyped]).void }
      def initialize(params = {})
        @processed = T.let(0, Integer)
        @failed = T.let(0, Integer)
        @retried = T.let(0, Integer)

        @created_at = T.let(nil, T.nilable(Integer))
        @updated_at = T.let(nil, T.nilable(Integer))
        @version = T.let(nil, T.nilable(Integer))

        super
      end
    end
  end
end
