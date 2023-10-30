# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple queue abstraction on top of Redis
  #
  class SubQueue
    extend T::Sig

    sig { returns(Queue) }
    attr_reader :queue

    sig { returns(String) }
    attr_reader :name

    sig { params(queue: Queue, type: T.nilable(String)).void }
    def initialize(queue, type = nil)
      @queue = queue
      @name = [queue.name, type].compact.join(":")
    end

    sig { params(id: Identifier).void }
    def add(id)
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        r.rpush(name, id)
      end
    end

    sig { params(id: Identifier).void }
    def remove(id)
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        r.lrem(name, 0, id)
      end
    end

    sig { returns(T.nilable(Identifier)) }
    def peek
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        r.lindex(name, 0)&.to_i
      end
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        # Get all identifiers from queue
        ids = r.lrange(name, 0, -1)

        # Delete all data and clear queue
        r.del(*ids.flat_map { |id| ["#{queue.name}:data:#{id}", "#{queue.name}:metadata:#{id}"] }, name, "#{queue.name}:id")

        # Return identifiers
        ids.map(&:to_i)
      end
    end

    sig { returns(Integer) }
    def size
      queue.redis.with { |r| r.llen(name) }
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end
  end
end
