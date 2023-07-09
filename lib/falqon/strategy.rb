# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Base class for retry strategies
  #
  class Strategy
    extend T::Sig

    sig { returns(Queue) }
    attr_reader :queue

    sig { params(queue: Queue).void }
    def initialize(queue)
      @queue = queue
    end

    sig { params(entry: Entry).void }
    def retry(entry)
      raise NotImplementedError
    end
  end
end
