# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    extend T::Sig

    sig { returns(String) }
    attr_reader :id

    sig { returns(String) }
    attr_reader :name

    sig { returns(Strategy) }
    attr_reader :retry_strategy

    sig { returns(Integer) }
    attr_reader :max_retries

    sig { returns(ConnectionPool) }
    attr_reader :redis

    sig { returns(Logger) }
    attr_reader :logger

    sig { params(id: String, retry_strategy: Symbol, max_retries: Integer, redis: ConnectionPool, logger: Logger).void }
    def initialize(id, retry_strategy: Falqon.configuration.retry_strategy, max_retries: Falqon.configuration.max_retries, redis: Falqon.configuration.redis, logger: Falqon.configuration.logger)
      @id = id
      @name = [Falqon.configuration.prefix, id].compact.join("/")
      @retry_strategy = Strategies.const_get(retry_strategy.to_s.capitalize).new(self)
      @max_retries = max_retries
      @redis = redis
      @logger = logger
    end

    sig { params(messages: Message).returns(T.any(Identifier, T::Array[Identifier])) }
    def push(*messages)
      logger.debug "Pushing #{messages.size} messages onto queue #{name}"

      messages.map do |message|
        entry = Entry
          .new(self, message:)
          .create

        # Push identifier to queue
        pending.add(entry.id)

        # Return identifier(s)
        messages.size == 1 ? (return entry.id) : (next entry.id)
      end
    end

    sig { params(block: T.nilable(T.proc.params(message: Message).void)).returns(T.nilable(Message)) }
    def pop(&block)
      logger.debug "Popping message from queue #{name}"

      entry = redis.with do |r|
        # Move identifier from pending queue to processing queue
        id = r.blmove(name, processing.name, :left, :right).to_i

        # Retrieve message
        Entry.new(self, id:)
      end

      message = entry.message

      yield message if block

      # Remove identifier from processing queue
      processing.remove(entry.id)

      # Delete message
      entry.delete

      message
    rescue Error => e
      logger.debug "Error processing message #{entry.id}: #{e.message}"

      # Retry message according to configured strategy
      retry_strategy.retry(entry.id)

      nil
    end

    sig { returns(T.nilable(Message)) }
    def peek
      logger.debug "Peeking at next message in queue #{name}"

      # Get identifier from pending queue
      id = pending.peek

      return unless id

      # Retrieve message
      Entry.new(self, id:).message
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      logger.debug "Clearing queue #{name}"

      # Clear all sub-queues
      pending.clear + processing.clear + dead.clear
    end

    sig { returns(Integer) }
    def size
      pending.size
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end

    sig { returns(SubQueue) }
    def pending
      @pending ||= SubQueue.new(self)
    end

    sig { returns(SubQueue) }
    def processing
      @processing ||= SubQueue.new(self, "processing")
    end

    sig { returns(SubQueue) }
    def dead
      @dead ||= SubQueue.new(self, "dead")
    end
  end
end
