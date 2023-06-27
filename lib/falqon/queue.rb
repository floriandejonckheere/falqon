# frozen_string_literal: true

# typed: true

require "forwardable"

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    extend Forwardable
    extend T::Sig

    sig { returns(String) }
    attr_reader :name

    sig { returns(Integer) }
    attr_reader :max_retries

    sig { params(name: String, max_retries: Integer).void }
    def initialize(name, max_retries: 3)
      @name = "#{Falqon.configuration.prefix}/#{name}"
      @max_retries = max_retries
    end

    # Push one or more messages to the queue
    sig { params(messages: String).returns(T::Array[Integer]) }
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

          # Return identifier
          next id
        end
      end
    end

    # Pop an message from the queue
    sig { params(block: T.nilable(T.proc.params(message: String).void)).returns(T.nilable(String)) }
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

    # Clear the queue
    sig { returns(Integer) }
    def clear
      logger.debug "Clearing queue #{name}"

      redis.with do |r|
        # Get all identifiers from queue
        ids = r.lrange(name, 0, -1)

        # Delete all messages and clear queue
        r.del(*ids.flat_map { |id| ["#{name}:messages:#{id}", "#{name}:retries:#{id}"] }, name, "#{name}:id")

        # Return number of deleted messages
        ids.size
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

    def_delegator :Falqon, :redis
    def_delegator :Falqon, :logger
  end
end
