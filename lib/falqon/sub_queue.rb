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

    sig { params(messages: Message).returns(T.any(Identifier, T::Array[Identifier])) }
    def add(*messages)
      queue.redis.with do |r|
        messages.map do |message|
          # Generate unique identifier
          id = r.incr("#{name}:id")

          r.multi do |t|
            # Store message
            t.set("#{name}:messages:#{id}", message)

            # Push identifier to queue
            r.rpush(name, id)
          end

          # Return identifier(s)
          messages.size == 1 ? (return id) : (next id)
        end
      end
    end

    sig { params(to: SubQueue).returns(T::Array[T.untyped]) }
    def move(to)
      queue.redis.with do |r|
        [
          # Move identifier from queue to queue
          id = r.blmove(name, to.name, :left, :right).to_i,

          # Retrieve message
          r.get("#{name}:messages:#{id}"),
        ]
      end
    end

    sig { params(id: Identifier).void }
    def remove(id)
      queue.redis.with do |r|
        # Remove identifier from queue
        r.lrem(name, 0, id)

        # Delete message
        r.del("#{name}:messages:#{id}", "#{name}:retries:#{id}")
      end

      nil
    end

    sig { returns(T.nilable(Message)) }
    def peek
      queue.redis.with do |r|
        # Get identifier from queue
        id = r.lindex(name, 0)&.to_i

        next unless id

        # Retrieve message
        r.get("#{name}:messages:#{id}")
      end
    end

    sig { returns(T::Array[Identifier]) }
    def clear
      queue.redis.with do |r|
        # Get all identifiers from queue
        ids = r.lrange(name, 0, -1)

        # Delete all messages and clear queue
        r.del(*ids.flat_map { |id| ["#{name}:messages:#{id}", "#{name}:retries:#{id}"] }, name, "#{name}:id")

        # Return identifiers
        ids.map(&:to_i)
      end
    end

    sig { returns(Integer) }
    def size
      queue.redis.with { |r| r.llen(name) }
    end
  end
end
