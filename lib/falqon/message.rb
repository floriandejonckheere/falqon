# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Represents a message on the queue
  #
  class Message
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :id

    sig { returns(String) }
    attr_reader :data

    sig { returns(Queue) }
    attr_reader :queue

    def initialize(queue, **attributes)
      @queue = queue

      attributes.each { |k, v| send(:"#{k}=", v) }
    end

    def get

    end

    def save
      redis.with do |r|
        # Generate unique identifier
        @id = r.incr("#{queue.name}:id")

        r.multi do |t|
          # Store message
          t.set("#{queue.name}:messages:#{id}", data)

          # Push identifier to queue
          t.rpush(queue.name, id)
        end
      end
    end

    def delete

    end

    def_delegator :Falqon, :redis
    def_delegator :Falqon, :logger
  end
end
