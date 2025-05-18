# frozen_string_literal: true

# typed: strict

module Falqon
  class Message
    ##
    # Message metadata storing various statistics and information about a message
    #
    class Metadata
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
        @status = T.let("unknown", String)
        @retries = T.let(0, Integer)

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
        # Transform keys to symbols, and values to integers
        new(data.to_h { |k, v| [k.to_sym, (send(props.dig(k.to_sym, :type).name.to_sym, v) if v)] })
      end
    end
  end
end
