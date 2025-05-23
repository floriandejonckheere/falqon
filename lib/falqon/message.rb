# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # A message in a queue
  #
  # This class should typically not be instantiated directly, but rather be created by a queue instance.
  #
  class Message
    extend Forwardable
    extend T::Sig

    # The queue instance the message belongs to
    sig { returns(Queue) }
    attr_reader :queue

    # Create a new message
    #
    # @param queue [Queue] The queue instance the message belongs to
    # @param id [Integer] The message identifier (optional if creating a new message)
    # @param data [String] The message data (optional if fetching an existing message)
    # @return The message instance
    #
    # @example Instantiate an existing message
    #   queue = Falqon::Queue.new("my_queue")
    #   id = queue.push("Hello, World!")
    #   message = Falqon::Message.new(queue, id:)
    #   message.data # => "Hello, World!"
    #
    # @example Create a new message
    #   queue = Falqon::Queue.new("my_queue")
    #   message = Falqon::Message.new(queue, data: "Hello, World!")
    #   message.create
    #   message.id # => 1
    #
    sig { params(queue: Queue, id: T.nilable(Identifier), data: T.nilable(Data)).void }
    def initialize(queue, id: nil, data: nil)
      @queue = queue
      @id = id
      @data = data
    end

    # The message identifier
    sig { returns(Identifier) }
    def id
      @id ||= redis.with { |r| r.incr("#{queue.id}:id") }
    end

    # The message data
    sig { returns(String) }
    def data
      @data ||= redis.with { |r| r.get("#{queue.id}:data:#{id}") }
    end

    # Whether the message status is unknown
    sig { returns(T::Boolean) }
    def unknown?
      metadata.status == "unknown"
    end

    # Whether the message status is pending
    sig { returns(T::Boolean) }
    def pending?
      metadata.status == "pending"
    end

    # Whether the message status is processing
    sig { returns(T::Boolean) }
    def processing?
      metadata.status == "processing"
    end

    # Whether the message status is scheduled
    sig { returns(T::Boolean) }
    def scheduled?
      metadata.status == "scheduled"
    end

    # Whether the message status is dead
    sig { returns(T::Boolean) }
    def dead?
      metadata.status == "dead"
    end

    # Whether the message exists (i.e. has been created)
    sig { returns(T::Boolean) }
    def exists?
      redis.with do |r|
        r.exists("#{queue.id}:data:#{id}") == 1
      end
    end

    # Create the message in the queue
    #
    # This method will overwrite any existing message with the same identifier.
    #
    # @return The message instance
    #
    sig { returns(Message) }
    def create
      redis.with do |r|
        message_id = id

        r.multi do |t|
          # Store data
          t.set("#{queue.id}:data:#{message_id}", data)

          # Set metadata
          t.hset("#{queue.id}:metadata:#{message_id}",
                 :created_at, Time.now.to_i,
                 :updated_at, Time.now.to_i,)
        end
      end

      self
    end

    # Kill the message
    #
    # This method moves the message to the dead queue, and resets the retry count.
    #
    sig { void }
    def kill
      logger.debug "Killing message #{id} on queue #{queue.name}"

      redis.with do |r|
        # Add identifier to dead queue
        queue.dead.add(id)

        # Reset retry count and set status to dead
        r.hdel("#{queue.id}:metadata:#{id}", :retries)
        r.hset("#{queue.id}:metadata:#{id}", :status, "dead")

        # Remove identifier from queues
        queue.pending.remove(id)
      end
    end

    # Delete the message, removing it from the queue
    #
    # This method deletes the message, metadata, and data from the queue.
    #
    sig { void }
    def delete
      redis.with do |r|
        r.multi do |t|
          # Delete message from queue
          queue.pending.remove(id)
          queue.dead.remove(id)

          # Delete data and metadata
          t.del("#{queue.id}:data:#{id}", "#{queue.id}:metadata:#{id}")
        end
      end
    end

    # Message length
    #
    # @return The string length of the message (in bytes)
    #
    sig { returns Integer }
    def size
      redis.with { |r| r.strlen("#{queue.id}:data:#{id}") }
    end

    # Metadata of the message
    #
    # @return The metadata of the message
    # @see Falqon::Message::Metadata
    #
    sig { returns Metadata }
    def metadata
      queue.redis.with do |r|
        Metadata
          .parse(r.hgetall("#{queue.id}:metadata:#{id}"))
      end
    end

    sig { returns(String) }
    def inspect
      "#<#{self.class} id=#{id.inspect} size=#{size.inspect}>"
    end

    def_delegator :queue, :redis
    def_delegator :queue, :logger
  end
end
