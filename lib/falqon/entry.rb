# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # An entry in a queue
  #
  class Entry
    extend Forwardable
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
      @id ||= redis.with { |r| r.incr("#{name}:id") }
    end

    sig { returns(String) }
    def message
      # FIXME: use Redis connection of caller
      @message ||= redis.with { |r| r.get("#{name}:messages:#{id}") }
    end

    sig { returns(T::Boolean) }
    def unknown?
      metadata.status == "unknown"
    end

    sig { returns(T::Boolean) }
    def pending?
      metadata.status == "pending"
    end

    sig { returns(T::Boolean) }
    def processing?
      metadata.status == "processing"
    end

    sig { returns(T::Boolean) }
    def dead?
      metadata.status == "dead"
    end

    sig { returns(T::Boolean) }
    def exists?
      # FIXME: use Redis connection of caller
      redis.with do |r|
        r.exists("#{name}:messages:#{id}") == 1
      end
    end

    sig { returns(Entry) }
    def create
      # FIXME: use Redis connection of caller
      redis.with do |r|
        # Store message
        r.set("#{name}:messages:#{id}", message)

        # Set metadata
        r.hset("#{name}:metadata:#{id}",
               :created_at, Time.now.to_i,
               :updated_at, Time.now.to_i,)
      end

      self
    end

    sig { void }
    def kill
      logger.debug "Killing message #{id} on queue #{name}"

      # FIXME: use Redis connection of caller
      redis.with do |r|
        # Add identifier to dead queue
        queue.dead.add(id)

        # Reset retry count and set status to dead
        r.hdel("#{name}:metadata:#{id}", :retries)
        r.hset("#{name}:metadata:#{id}", :status, "dead")

        # Remove identifier from queues
        queue.pending.remove(id)
      end
    end

    sig { void }
    def delete
      # FIXME: use Redis connection of caller
      redis.with do |r|
        # Delete message from queue
        queue.pending.remove(id)
        queue.dead.remove(id)

        # Delete message and metadata
        r.del("#{name}:messages:#{id}", "#{name}:metadata:#{id}")
      end
    end

    sig { returns Metadata }
    def metadata
      queue.redis.with do |r|
        Metadata
          .new(r
            .hgetall("#{name}:metadata:#{id}")
            .to_h { |k, v| [k.to_sym, k == "status" ? v : v.to_i] }) # Transform all keys to symbols, and values to integers (except status)
      end
    end

    def_delegator :queue, :redis
    def_delegator :queue, :logger
    def_delegator :queue, :name

    ##
    # Metadata for an entry
    #
    class Metadata < T::Struct
      # Status (unknown, pending, processing, dead)
      prop :status, String, default: "unknown"

      # Number of times the message has been retried
      prop :retries, Integer, default: 0

      # Timestamp of creation
      prop :created_at, Integer

      # Timestamp of last update
      prop :updated_at, Integer
    end
  end
end
