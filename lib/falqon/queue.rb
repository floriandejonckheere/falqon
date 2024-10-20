# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    include Hooks
    extend T::Sig

    # The name of the queue (without prefix)
    sig { returns(String) }
    attr_reader :name

    # The identifier of the queue (with prefix)
    sig { returns(String) }
    attr_reader :id

    # The configured retry strategy of the queue
    sig { returns(Strategy) }
    attr_reader :retry_strategy

    # The maximum number of retries before a message is considered failed
    sig { returns(Integer) }
    attr_reader :max_retries

    # The delay in seconds before a message is eligible for a retry
    sig { returns(Integer) }
    attr_reader :retry_delay

    # @!visibility private
    sig { returns(ConnectionPool) }
    attr_reader :redis

    # @!visibility private
    sig { returns(Logger) }
    attr_reader :logger

    # Create a new queue
    #
    # Create a new queue in Redis with the given name. If a queue with the same name already exists, it is reused.
    # When registering a new queue, the following {Falqon::Queue::Metadata} is stored:
    # - +created_at+: Timestamp of creation
    # - +updated_at+: Timestamp of last update
    # - +version+: Protocol version
    #
    # Initializing a queue with a different protocol version than the existing queue will raise a {Falqon::VersionMismatchError}.
    # Currently queues are not compatible between different protocol versions, and must be deleted and recreated manually.
    # In a future version, automatic migration between protocol versions may be supported.
    #
    # Please note that retry strategy, maximum retries, and retry delay are configured per queue instance, and are not shared between queue instances.
    #
    # @param name The name of the queue (without prefix)
    # @param retry_strategy The retry strategy to use for failed messages
    # @param max_retries The maximum number of retries before a message is considered failed
    # @param retry_delay The delay in seconds before a message is eligible for a retry
    # @param redis The Redis connection pool to use
    # @param logger The logger to use
    # @param version The protocol version to use
    # @return The new queue
    # @raise [Falqon::VersionMismatchError] if the protocol version of the existing queue does not match the protocol version of the new queue
    #
    # @example Create a new queue
    #   queue = Falqon::Queue.new("my_queue")
    #   queue.name # => "my_queue"
    #   queue.id # => "falqon/my_queue"
    #
    sig { params(name: String, retry_strategy: Symbol, max_retries: Integer, retry_delay: Integer, redis: ConnectionPool, logger: Logger, version: Integer).void }
    def initialize(
      name,
      retry_strategy: Falqon.configuration.retry_strategy,
      max_retries: Falqon.configuration.max_retries,
      retry_delay: Falqon.configuration.retry_delay,
      redis: Falqon.configuration.redis,
      logger: Falqon.configuration.logger,
      version: Falqon::PROTOCOL
    )
      @name = name
      @id = [Falqon.configuration.prefix, name].compact.join("/")
      @retry_strategy = Strategies.const_get(retry_strategy.to_s.capitalize).new(self)
      @max_retries = max_retries
      @retry_delay = retry_delay
      @redis = redis
      @logger = logger
      @version = version

      redis.with do |r|
        queue_version = r.hget("#{id}:metadata", :version)

        raise Falqon::VersionMismatchError, "Queue #{name} is using protocol version #{queue_version}, but this client is using protocol version #{version}" if queue_version && queue_version.to_i != @version

        # Register the queue
        r.sadd([Falqon.configuration.prefix, "queues"].compact.join(":"), name)

        # Set creation and update timestamp (if not set)
        r.hsetnx("#{id}:metadata", :created_at, Time.now.to_i)
        r.hsetnx("#{id}:metadata", :updated_at, Time.now.to_i)

        # Set protocol version
        r.hsetnx("#{id}:metadata", :version, @version)
      end

      run_hook :initialize, :after
    end

    # Push data onto the tail of the queue
    #
    # @param data The data to push onto the queue (one or more strings)
    # @return The identifier(s) of the pushed message(s)
    #
    # @example Push a single message
    #   queue = Falqon::Queue.new("my_queue")
    #   queue.push("Hello, world!") # => "1"
    #
    # @example Push multiple messages
    #   queue = Falqon::Queue.new("my_queue")
    #   queue.push("Hello, world!", "Goodbye, world!") # => ["1", "2"]
    #
    sig { params(data: Data).returns(T.any(Identifier, T::Array[Identifier])) }
    def push(*data)
      logger.debug "Pushing #{data.size} messages onto queue #{name}"

      run_hook :push, :before

      # Set update timestamp
      redis.with { |r| r.hset("#{id}:metadata", :updated_at, Time.now.to_i) }

      ids = data.map do |d|
        message = Message
          .new(self, data: d)
          .create

        # Push identifier to queue
        pending.add(message.id)

        # Set message status
        redis.with { |r| r.hset("#{id}:metadata:#{message.id}", :status, "pending") }

        # Return identifier(s)
        data.size == 1 ? (return message.id) : (next message.id)
      end

      run_hook :push, :after

      # Return identifier(s)
      ids
    end

    # Pop data from the head of the queue
    #
    # This method blocks until a message is available.
    # If a block is given, the popped data is passed to the block. If the block raises a {Falqon::Error} exception, the message is retried according to the configured retry strategy.
    # If no block is given, the popped data is returned.
    #
    # @param block A block to execute with the popped data (block-style)
    # @return The popped data (return-style)
    #
    # @example Pop a message (return-style)
    #   queue = Falqon::Queue.new("my_queue")
    #   queue.push("Hello, world!")
    #   queue.pop # => "Hello, world!"
    #
    # @example Pop a message (block-style)
    #   queue = Falqon::Queue.new("my_queue")
    #   queue.push("Hello, world!")
    #   queue.pop do |data|
    #     puts data # => "Hello, world!"
    #   end
    #
    sig { params(block: T.nilable(T.proc.params(data: Data).void)).returns(T.nilable(Data)) }
    def pop(&block)
      logger.debug "Popping message from queue #{name}"

      run_hook :pop, :before

      message = redis.with do |r|
        # Move identifier from pending queue to processing queue
        message_id = r.blmove(pending.id, processing.id, :left, :right).to_i

        # Set message status
        r.hset("#{id}:metadata:#{message_id}", :status, "processing")

        # Set update timestamp
        r.hset("#{id}:metadata", :updated_at, Time.now.to_i)
        r.hset("#{id}:metadata:#{message_id}", :updated_at, Time.now.to_i)

        # Increment processing counter
        r.hincrby("#{id}:metadata", :processed, 1)

        # Increment retry counter if message is retried
        r.hincrby("#{id}:metadata", :retried, 1) if r.hget("#{id}:metadata:#{message_id}", :retries).to_i.positive?

        Message.new(self, id: message_id)
      end

      data = message.data

      yield data if block

      run_hook :pop, :after

      # Remove identifier from processing queue
      processing.remove(message.id)

      # Delete message
      message.delete

      data
    rescue Error => e
      logger.debug "Error processing message #{message.id}: #{e.message}"

      # Increment failure counter
      redis.with { |r| r.hincrby("#{id}:metadata", :failed, 1) }

      # Retry message according to configured strategy
      retry_strategy.retry(message)

      nil
    end

    # Peek at the next message in the queue
    #
    # Use {#range} to peek at a range of messages.
    # This method does not block.
    #
    # @param index The index of the message to peek at
    # @return The data of the peeked message
    #
    sig { params(index: Integer).returns(T.nilable(Data)) }
    def peek(index: 0)
      logger.debug "Peeking at next message in queue #{name}"

      run_hook :peek, :before

      # Get identifier from pending queue
      message_id = pending.peek(index:)

      return unless message_id

      run_hook :peek, :after

      # Retrieve data
      Message.new(self, id: message_id).data
    end

    # Peek at the next messages in the queue
    #
    # Use {#peek} to peek at a single message.
    # This method does not block.
    #
    # @param start The start index of the range to peek at
    # @param stop The stop index of the range to peek at (set to -1 to peek at all messages)
    # @return The data of the peeked messages
    #
    sig { params(start: Integer, stop: Integer).returns(T::Array[Data]) }
    def range(start: 0, stop: -1)
      logger.debug "Peeking at next messages in queue #{name}"

      run_hook :range, :before

      # Get identifiers from pending queue
      message_ids = pending.range(start:, stop:)

      return [] unless message_ids.any?

      run_hook :range, :after

      # Retrieve data
      message_ids.map { |id| Message.new(self, id:).data }
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      logger.debug "Clearing queue #{name}"

      run_hook :clear, :before

      # Clear all sub-queues
      message_ids = pending.clear + processing.clear + scheduled.clear + dead.clear

      redis.with do |r|
        # Clear metadata
        r.hdel("#{id}:metadata", :processed, :failed, :retried)

        # Set update timestamp
        r.hset("#{id}:metadata", :updated_at, Time.now.to_i)
      end

      run_hook :clear, :after

      # Return identifiers
      message_ids
    end

    sig { void }
    def delete
      logger.debug "Deleting queue #{name}"

      run_hook :delete, :before

      # Delete all sub-queues
      [pending, processing, scheduled, dead]
        .each(&:clear)

      redis.with do |r|
        # Delete metadata
        r.del("#{id}:metadata")

        # Deregister the queue
        r.srem([Falqon.configuration.prefix, "queues"].compact.join(":"), name)
      end

      run_hook :delete, :after
    end

    sig { returns(T::Array[Identifier]) }
    def refill
      logger.debug "Refilling queue #{name}"

      run_hook :refill, :before

      message_ids = []

      # Move all identifiers from tail of processing queue to head of pending queue
      redis.with do |r|
        while (message_id = r.lmove(processing.id, id, :right, :left))
          # Set message status
          r.hset("#{id}:metadata:#{message_id}", :status, "pending")

          message_ids << message_id
        end
      end

      run_hook :refill, :after

      message_ids
    end

    sig { returns(T::Array[Identifier]) }
    def revive
      logger.debug "Reviving queue #{name}"

      run_hook :revive, :before

      message_ids = []

      # Move all identifiers from tail of dead queue to head of pending queue
      redis.with do |r|
        while (message_id = r.lmove(dead.id, id, :right, :left))
          # Set message status
          r.hset("#{id}:metadata:#{message_id}", :status, "pending")

          message_ids << message_id
        end
      end

      run_hook :revive, :after

      message_ids
    end

    sig { returns(T::Array[Identifier]) }
    def schedule
      logger.debug "Scheduling failed messages on queue #{name}"

      run_hook :schedule, :before

      message_ids = T.let([], T::Array[Identifier])

      # Move all due identifiers from scheduled queue to head of pending queue
      redis.with do |r|
        # Select all identifiers that are due (score <= current timestamp)
        # FIXME: replace with zrange(by_score: true) when https://github.com/sds/mock_redis/issues/307 is resolved
        message_ids = r.zrangebyscore(scheduled.id, 0, Time.now.to_i).map(&:to_i)

        logger.debug "Scheduling messages #{message_ids.join(', ')} on queue #{name}"

        message_ids.each do |message_id|
          # Set message status
          r.hset("#{id}:metadata:#{message_id}", :status, "pending")

          # Add identifier to pending queue
          pending.add(message_id)

          # Remove identifier from scheduled queue
          scheduled.remove(message_id)
        end
      end

      run_hook :schedule, :after

      message_ids
    end

    sig { returns(Integer) }
    def size
      pending.size
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end

    sig { returns Metadata }
    def metadata
      redis.with do |r|
        Metadata
          .new r
          .hgetall("#{id}:metadata")
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

    sig { returns(SubSet) }
    def scheduled
      @scheduled ||= SubSet.new(self, "scheduled")
    end

    sig { returns(SubQueue) }
    def dead
      @dead ||= SubQueue.new(self, "dead")
    end

    sig { returns(String) }
    def inspect
      "#<#{self.class} name=#{name.inspect} pending=#{pending.size} processing=#{processing.size} scheduled=#{scheduled.size} dead=#{dead.size}>"
    end

    class << self
      def all
        Falqon.configuration.redis.with do |r|
          r
            .smembers([Falqon.configuration.prefix, "queues"].compact.join(":"))
            .map { |id| new(id) }
        end
      end

      def size
        Falqon.configuration.redis.with do |r|
          r
            .scard([Falqon.configuration.prefix, "queues"].compact.join(":"))
        end
      end
    end

    ##
    # Queue metadata
    #
    class Metadata < T::Struct
      # Total number of messages processed
      prop :processed, Integer, default: 0

      # Total number of messages failed
      prop :failed, Integer, default: 0

      # Total number of messages retried
      prop :retried, Integer, default: 0

      # Timestamp of creation
      prop :created_at, Integer

      # Timestamp of last update
      prop :updated_at, Integer

      # Protocol version
      prop :version, Integer
    end
  end
end
