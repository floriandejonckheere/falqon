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

    sig { params(name: String, prefix: String).void }
    def initialize(name, prefix: "falqon")
      @name = "#{prefix}/#{name}"
    end

    # Push one or more items to the queue
    sig { params(items: String).returns(T::Array[Integer]) }
    def push(*items)
      logger.debug "Pushing #{items.size} items onto queue #{name}"

      redis.with do |r|
        items.map do |item|
          # Generate unique identifier
          id = r.incr("#{name}:id")

          r.multi do |t|
            # Store item
            t.set("#{name}:items:#{id}", item)

            # Push identifier to queue
            t.rpush(name, id)
          end

          # Return identifier
          next id
        end
      end
    end

    # Pop an item from the queue
    sig { params(block: T.nilable(T.proc.params(item: String).void)).returns(T.nilable(String)) }
    def pop(&block)
      logger.debug "Popping item from queue #{name}"

      id, item = redis.with do |r|
        [
          # Move identifier from queue to processing queue
          id = r.blmove(name, "#{name}:processing", :left, :right).to_i,

          # Retrieve item
          r.get("#{name}:items:#{id}"),
        ]
      end

      yield item if block

      redis.with do |r|
        # Remove identifier from processing queue
        r.lrem("#{name}:processing", 0, id)

        # Delete item
        r.del("#{name}:items:#{id}")
      end

      item
    rescue Error => e
      logger.debug "Error processing item #{id}: #{e.message}"

      redis.with do |r|
        r.multi do |t|
          # Add identifier back to queue
          t.rpush(name, id)

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

        # Delete all items and clear queue
        r.del(*ids.map { |id| "#{name}:items:#{id}" }, name, "#{name}:id")

        # Return number of deleted items
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
