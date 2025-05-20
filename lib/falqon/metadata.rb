# frozen_string_literal: true

# typed: strict

module Falqon
  ##
  # Metadata base class
  #
  class Metadata
    extend T::Sig
    include T::Props

    # Create a Metadata object
    sig { params(params: T::Hash[Symbol, T.untyped]).void }
    def initialize(params = {})
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
