# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # An entry in a queue
  #
  class Entry
    extend T::Sig

    sig { returns(Queue) }
    attr_reader :queue

    sig { params(queue: Queue, id: T.nilable(Identifier), message: T.nilable(Message)).void }
    def initialize(queue, id: nil, message: nil)
      @queue = queue
      @id = id
      @message = message
    end

    sig { returns(Identifier) }
    def id
      # FIXME: use Redis connection of caller
      @id ||= queue.redis.with { |r| r.incr("#{queue.name}:id") }
    end

    sig { returns(String) }
    def message
      # FIXME: use Redis connection of caller
      @message ||= queue.redis.with { |r| r.get("#{queue.name}:messages:#{id}") }
    end

    sig { returns(Entry) }
    def create
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        # Store message
        r.set("#{queue.name}:messages:#{id}", message)

        # Set creation and update timestamp
        r.hset("#{queue.name}:stats:#{id}", :created_at, Time.now.to_i)
      end

      self
    end

    sig { void }
    def delete
      # FIXME: use Redis connection of caller
      queue.redis.with do |r|
        # Delete message
        r.del("#{queue.name}:messages:#{id}", "#{queue.name}:stats:#{id}")
      end
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
  end
end
