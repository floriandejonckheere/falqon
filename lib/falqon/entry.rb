# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # An entry in a queue
  #
  class Entry
    include Touch
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

    sig { returns(Entry) }
    def create
      # FIXME: use Redis connection of caller
      redis.with do |r|
        # Store message
        r.set("#{name}:messages:#{id}", message)

        # Set creation and update timestamp
        r.hset("#{name}:stats:#{id}",
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

        # Reset retry count
        r.hdel("#{name}:stats:#{id}", :retries)

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
        r.del("#{name}:messages:#{id}", "#{name}:stats:#{id}")
      end
    end

    sig { returns Statistics }
    def stats
      queue.redis.with do |r|
        Statistics
          .new r
          .hgetall("#{name}:stats:#{id}")
          .transform_keys(&:to_sym)
          .transform_values(&:to_i)
      end
    end

    def_delegator :queue, :redis
    def_delegator :queue, :logger
    def_delegator :queue, :name

    ##
    # Statistics for an entry
    #
    class Statistics < T::Struct
      # Number of times the message has been retried
      prop :retries, Integer, default: 0

      # Timestamp of creation
      prop :created_at, Integer

      # Timestamp of last update
      prop :updated_at, Integer
    end
  end
end
