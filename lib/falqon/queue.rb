# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { returns(Integer) }
    attr_reader :max_retries

    sig { returns(ConnectionPool) }
    attr_reader :redis

    sig { returns(Logger) }
    attr_reader :logger

    sig { params(name: String, max_retries: Integer, redis: ConnectionPool, logger: Logger).void }
    def initialize(name, max_retries: Falqon.configuration.max_retries, redis: Falqon.configuration.redis, logger: Falqon.configuration.logger)
      @name = [Falqon.configuration.prefix, name].compact.join("/")
      @max_retries = max_retries
      @redis = redis
      @logger = logger
    end

    # Push one or more messages to the queue
    sig { params(messages: Message).returns(T.any(Identifier, T::Array[Identifier])) }
    def push(*messages)
      logger.debug "Pushing #{messages.size} messages onto queue #{name}"

      redis.with do |r|
        messages.map do |message|
          # Generate unique identifier
          id = r.incr("#{name}:id")

          r.multi do |t|
            # Store message
            t.set("#{name}:messages:#{id}", message)

            # Push identifier to queue
            t.rpush(name, id)
          end

          # Return identifier(s)
          messages.size == 1 ? (return id) : (next id)
        end
      end
    end

    # Pop a message from the queue
    sig { params(block: T.nilable(T.proc.params(message: Message).void)).returns(T.nilable(Message)) }
    def pop(&block)
      logger.debug "Popping message from queue #{name}"

      id, message = redis.with do |r|
        [
          # Move identifier from queue to processing queue
          id = r.blmove(name, "#{name}:processing", :left, :right).to_i,

          # Retrieve message
          r.get("#{name}:messages:#{id}"),
        ]
      end

      yield message if block

      redis.with do |r|
        # Remove identifier from processing queue
        r.lrem("#{name}:processing", 0, id)

        # Delete message
        r.del("#{name}:messages:#{id}", "#{name}:retries:#{id}")
      end

      message
    rescue Error => e
      logger.debug "Error processing message #{id}: #{e.message}"

      redis.with do |r|
        # Increment retry count
        retries = r.incr("#{name}:retries:#{id}")

        r.multi do |t|
          if retries < max_retries
            logger.debug "Requeuing message #{id} on queue #{name} (attempt #{retries})"

            # Add identifier back to queue
            t.rpush(name, id)
          else
            logger.debug "Discarding message #{id} on queue #{name} (attempt #{retries})"

            # Add identifier to dead queue
            t.rpush("#{name}:dead", id)

            # Clear retry count
            t.del("#{name}:retries:#{id}")
          end

          # Remove identifier from processing queue
          t.lrem("#{name}:processing", 0, id)
        end
      end

      nil
    end

    # Peek at the next message in the queue
    sig { returns(T.nilable(Message)) }
    def peek
      logger.debug "Peeking at next message in queue #{name}"

      redis.with do |r|
        # Get identifier from queue
        id = r.lindex(name, 0).to_i

        # Retrieve message
        r.get("#{name}:messages:#{id}")
      end
    end

    # Clear the queue
    sig { returns(T::Array[Identifier]) }
    def clear
      logger.debug "Clearing queue #{name}"

      redis.with do |r|
        # Get all identifiers from queue
        ids = r.lrange(name, 0, -1)

        # Delete all messages and clear queue
        r.del(*ids.flat_map { |id| ["#{name}:messages:#{id}", "#{name}:retries:#{id}"] }, name, "#{name}:id")

        # Return identifiers
        ids.map(&:to_i)
      end
    end

    # Size of the queue
    sig { returns(Integer) }
    def size
      redis.with { |r| r.llen(name) }
    end

    # Whether the queue is empty
    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end
  end
end
