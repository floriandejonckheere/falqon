# frozen_string_literal: true

# typed: strict

module Falqon
  class Message
    ##
    # Message metadata storing various statistics and information about a message
    #
    class Metadata < Falqon::Metadata
      extend T::Sig

      # Status (unknown, pending, processing, scheduled, dead)
      sig { returns(String) }
      attr_accessor :status

      # Number of times the message has been retried
      sig { returns(Integer) }
      attr_reader :retries

      sig { params(value: T.any(String, Integer)).void }
      def retries=(value)
        @retries = value.to_i
      end

      # Timestamp of last retry
      sig { returns(T.nilable(Integer)) }
      attr_reader :retried_at

      sig { params(value: T.nilable(T.any(String, Integer))).void }
      def retried_at=(value)
        @retried_at = value&.to_i
      end

      # Last error message
      sig { returns(T.nilable(String)) }
      attr_accessor :retry_error

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

      # @!visibility private
      sig { params(params: T::Hash[Symbol, T.untyped]).void }
      def initialize(params = {})
        @status = T.let("unknown", String)
        @retries = T.let(0, Integer)

        @retried_at = T.let(nil, T.nilable(Integer))
        @retry_error = T.let(nil, T.nilable(String))
        @created_at = T.let(nil, T.nilable(Integer))
        @updated_at = T.let(nil, T.nilable(Integer))

        super
      end
    end
  end
end
