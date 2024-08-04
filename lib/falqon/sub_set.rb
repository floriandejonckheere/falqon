# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Simple sorted set abstraction on top of Redis
  #
  class SubSet
    extend T::Sig

    sig { returns(String) }
    attr_reader :type

    sig { returns(String) }
    attr_reader :id

    sig { returns(Queue) }
    attr_reader :queue

    sig { params(queue: Queue, type: T.nilable(String)).void }
    def initialize(queue, type = nil)
      @type = type || "pending"
      @id = [queue.id, type].compact.join(":")
      @queue = queue
    end

    sig { params(message_id: Identifier, score: Integer).void }
    def add(message_id, score)
      queue.redis.with do |r|
        r.zadd(id, score, message_id)
      end
    end

    sig { params(message_id: Identifier).void }
    def remove(message_id)
      queue.redis.with do |r|
        r.zrem(id, message_id)
      end
    end

    sig { params(index: Integer).returns(T.nilable(Identifier)) }
    def peek(index: 0)
      queue.redis.with do |r|
        r.zrange(id, index, index).first&.to_i
      end
    end

    sig { params(start: Integer, stop: Integer).returns(T::Array[Identifier]) }
    def range(start: 0, stop: -1)
      queue.redis.with do |r|
        r.zrange(id, start, stop).map(&:to_i)
      end
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      queue.redis.with do |r|
        # Get all identifiers from queue
        message_ids = r.zrange(id, 0, -1)

        # Delete all data and clear queue
        r.del(*message_ids.flat_map { |message_id| ["#{queue.id}:data:#{message_id}", "#{queue.id}:metadata:#{message_id}"] }, id, "#{queue.id}:id")

        # Return identifiers
        message_ids.map(&:to_i)
      end
    end

    sig { returns(Integer) }
    def size
      queue.redis.with { |r| r.zcount(id, "-inf", "+inf") }
    end

    sig { returns(T::Boolean) }
    def empty?
      size.zero?
    end

    sig { returns(T::Array[Identifier]) }
    def to_a
      queue.redis.with { |r| r.zrange(id, 0, -1).map(&:to_i) }
    end

    sig { returns(String) }
    def inspect
      "#<#{self.class} name=#{type} size=#{size}>"
    end
  end
end
