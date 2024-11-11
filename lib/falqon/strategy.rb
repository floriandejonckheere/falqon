# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Base class for retry strategies
  # @!visibility private
  #
  class Strategy
    extend T::Sig

    sig { returns(Queue) }
    attr_reader :queue

    sig { params(queue: Queue).void }
    def initialize(queue)
      @queue = queue
    end

    sig { params(message: Message, error: Error).void }
    def retry(message, error)
      raise NotImplementedError
    end
  end
end
