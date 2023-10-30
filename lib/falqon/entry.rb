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

    sig { params(queue: Queue, id: T.nilable(Identifier), data: T.nilable(Data)).void }
    def initialize(queue, id: nil, data: nil)
      @queue = queue
      @id = id
      @data = data
    end

    sig { returns(Identifier) }
    def id
      # FIXME: use Redis connection of caller
      @id ||= redis.with { |r| r.incr("#{name}:id") }
    end

    sig { returns(String) }
    def data
      # FIXME: use Redis connection of caller
      @data ||= redis.with { |r| r.get("#{name}:data:#{id}") }
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
        r.exists("#{name}:data:#{id}") == 1
      end
    end

    sig { returns(Entry) }
    def create
      # FIXME: use Redis connection of caller
      redis.with do |r|
        # Store data
        r.set("#{name}:data:#{id}", data)

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

        # Delete data and metadata
        r.del("#{name}:data:#{id}", "#{name}:metadata:#{id}")
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
