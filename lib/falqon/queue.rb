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

    # Push one or more messages to the queue
    def push(*messages)
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

    # Pop a message from the queue
    def pop
      redis.with do |r|
        # Pop identifier from queue
        id = r.lpop(name).to_i

        # Retrieve message
        r.get("#{name}:messages:#{id}")
      end
    end

    # Clear the queue
    def clear
      redis.with do |r|
        # Get all identifiers from queue
        ids = r.lrange(name, 0, -1)

        # Delete all messages and clear queue
        r.del(*ids.map { |id| "#{name}:messages:#{id}" }, name, "#{name}:id")
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
