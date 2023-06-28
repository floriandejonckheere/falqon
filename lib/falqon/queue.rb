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
            queue.add(id)
          end

          # Return identifier(s)
          messages.size == 1 ? (return id) : (next id)
        end
      end
    end

    sig { params(block: T.nilable(T.proc.params(message: Message).void)).returns(T.nilable(Message)) }
    def pop(&block)
      logger.debug "Popping message from queue #{name}"

      id, message = redis.with do |r|
        [
          # Move identifier from queue to processing queue
          id = r.blmove(name, processing.name, :left, :right).to_i,

          # Retrieve message
          r.get("#{name}:messages:#{id}"),
        ]
      end

      yield message if block

      redis.with do |r|
        # Remove identifier from processing queue
        processing.remove(id)

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
            queue.add(id)
          else
            logger.debug "Discarding message #{id} on queue #{name} (attempt #{retries})"

            # Add identifier to dead queue
            dead.add(id)

            # Clear retry count
            t.del("#{name}:retries:#{id}")
          end

          # Remove identifier from processing queue
          t.lrem(processing.name, 0, id)
        end
      end

      nil
    end

    sig { returns(T.nilable(Message)) }
    def peek
      logger.debug "Peeking at next message in queue #{name}"

      redis.with do |r|
        # Get identifier from queue
        id = queue.peek

        next unless id

        # Retrieve message
        r.get("#{name}:messages:#{id}")
      end
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      logger.debug "Clearing queue #{name}"

      # Clear all sub-queues
      queue.clear + processing.clear + dead.clear
    end

    sig { returns(Integer) }
    def size
      queue.size
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end

    sig { returns(SubQueue) }
    def queue
      @queue ||= SubQueue.new(self)
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
