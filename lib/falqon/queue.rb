# frozen_string_literal: true

require "forwardable"

module Falqon
  ##
  # Simple, efficient queue implementation backed by Redis
  #
  class Queue
    extend Forwardable

    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Push one or more items to the queue
    def push(*items)
      redis.with do |r|
        items.each do |item|
          r.lpush(name, item)
        end
      end
    end

    # Pop an item from the queue
    def pop
      redis.with { |r| r.rpop(name) }
    end

    def_delegator :Falqon, :redis
  end
end
