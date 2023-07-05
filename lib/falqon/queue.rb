# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    include Hooks
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

      run_hook :initialize
    end

    sig { params(messages: Message).returns(T.any(Identifier, T::Array[Identifier])) }
    def push(*messages)
      logger.debug "Pushing #{messages.size} messages onto queue #{name}"

      run_hook :push, :before

      ids = messages.map do |message|
        entry = Entry
          .new(self, message:)
          .create

        # Push identifier to queue
        pending.add(entry.id)

        # Return identifier(s)
        messages.size == 1 ? (return entry.id) : (next entry.id)
      end

      run_hook :push, :after

      # Return identifier(s)
      ids
    end

    sig { params(block: T.nilable(T.proc.params(message: Message).void)).returns(T.nilable(Message)) }
    def pop(&block)
      logger.debug "Popping message from queue #{name}"

      run_hook :pop, :before

      entry = redis.with do |r|
        # Move identifier from pending queue to processing queue
        id = r.blmove(name, processing.name, :left, :right).to_i

        # Increment processing counter
        r.hincrby("#{name}:stats", :processed, 1)

        # Increment retry counter if message is retried
        r.hincrby("#{name}:stats", :retried, 1) if r.get("#{name}:retries:#{id}").to_i.positive?

        # Retrieve message
        Entry.new(self, id:)
      end

      message = entry.message

      yield message if block

      run_hook :pop, :after

      # Remove identifier from processing queue
      processing.remove(entry.id)

      # Delete message
      entry.delete

      message
    rescue Error => e
      logger.debug "Error processing message #{entry.id}: #{e.message}"

      # Increment failure counter
      redis.with { |r| r.hincrby("#{name}:stats", :failed, 1) }

      # Retry message according to configured strategy
      retry_strategy.retry(entry.id)

      nil
    end

    sig { returns(T.nilable(Message)) }
    def peek
      logger.debug "Peeking at next message in queue #{name}"

      run_hook :peek, :before

      # Get identifier from pending queue
      id = pending.peek

      return unless id

      run_hook :peek, :after

      # Retrieve message
      Entry.new(self, id:).message
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      logger.debug "Clearing queue #{name}"

      run_hook :clear, :before

      # Clear all sub-queues
      ids = pending.clear + processing.clear + dead.clear

      # Clear stats
      redis.with { |r| r.del("#{name}:stats") }

      run_hook :clear, :after

      # Return identifiers
      ids
    end

    sig { void }
    def delete
      logger.debug "Deleting queue #{name}"

      run_hook :delete, :before

      # Delete all sub-queues
      [pending, processing, dead]
        .each(&:clear)

      # Delete stats
      redis.with { |r| r.del("#{name}:stats") }

      run_hook :delete, :after
    end

    sig { returns(Integer) }
    def size
      pending.size
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end

    sig { returns T::Hash[Symbol, Integer] }
    def stats
      redis.with do |r|
        Hash
          .new { |h, k| h[k] = 0 }
          .merge r
          .hgetall("#{name}:stats")
          .transform_keys(&:to_sym)
          .transform_values(&:to_i)
      end
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
