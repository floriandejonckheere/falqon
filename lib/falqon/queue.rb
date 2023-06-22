# frozen_string_literal: true

require "forwardable"

module Falqon
  ##
  # Simple, efficient, and reliable messaging queue implementation
  #
  class Queue
    extend Forwardable

    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Push one or more items to the queue
    def push(*items)
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
    def pop
      redis.with do |r|
        # Pop identifier from queue
        id = r.lpop(name).to_i

        # Retrieve item
        r.get("#{name}:items:#{id}")
      end
    end

    # Clear the queue
    def clear
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
    def size
      redis.with { |r| r.llen(name) }
    end

    def empty?
      size.zero?
    end

    def_delegator :Falqon, :redis
  end
end
