# frozen_string_literal: true

# typed: strict

module Falqon
  ##
  # Metadata base class
  #
  class Metadata
    extend T::Sig

    # @!visibility private
    sig { params(params: T::Hash[Symbol, T.untyped]).void }
    def initialize(params = {})
      params.each do |key, value|
        send("#{key}=", value)
      end
    end

    # @!visibility private
    sig { params(data: T::Hash[String, String]).returns(T.attached_class) }
    def self.parse(data)
      new(data.transform_keys(&:to_sym))
    end
  end
end
