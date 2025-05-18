# frozen_string_literal: true

# typed: true

module Falqon
  ##
  # Falqon commands
  #
  module Commands
    extend T::Sig

    sig { returns(T.untyped) }
    def options # rubocop:disable Lint/UselessMethodDefinition
      super
    end

    # @!visibility private
    sig { params(base: T.class_of(Thor)).void }
    def self.included(base)
      base.class_eval do
        desc "version", "Display version"
        # @!visibility private
        def version
          Version
            .new(options)
            .call
        end

        desc "list", "Display all active (registered) queues"
        # @!visibility private
        def list
          List
            .new(options)
            .call
        end

        desc "status", "Display queue status"
        option :queue, aliases: "-q", type: :string, desc: "Queue name"
        # @!visibility private
        def status
          Status
            .new(options)
            .call
        end

        desc "stats", "Display queue statistics"
        option :queue, aliases: "-q", type: :string, desc: "Queue name"
        # @!visibility private
        def stats
          Stats
            .new(options)
            .call
        end

        desc "show", "Display messages in a queue"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

        option :pending, type: :boolean, desc: "Display pending messages (default)"
        option :processing, type: :boolean, desc: "Display processing messages"
        option :dead, type: :boolean, desc: "Display dead messages"

        option :data, aliases: "-d", type: :boolean, desc: "Display raw data"
        option :meta, aliases: "-m", type: :boolean, desc: "Display additional metadata"

        option :head, type: :numeric, desc: "Display N messages from head of queue"
        option :tail, type: :numeric, desc: "Display N messages from tail of queue"
        option :index, type: :numeric, desc: "Display message at index N", repeatable: true
        option :range, type: :array, desc: "Display messages at index N to M", banner: "N M"

        option :id, type: :numeric, desc: "Display message with ID N", repeatable: true
        # @!visibility private
        def show
          Show
            .new(options)
            .call
        end

        desc "delete", "Delete messages from a queue"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

        option :pending, type: :boolean, desc: "Delete only pending messages (default)"
        option :processing, type: :boolean, desc: "Delete only processing messages"
        option :dead, type: :boolean, desc: "Delete only dead messages"

        option :head, type: :numeric, desc: "Delete N messages from head of queue"
        option :tail, type: :numeric, desc: "Delete N messages from tail of queue"
        option :index, type: :numeric, desc: "Delete message at index N", repeatable: true
        option :range, type: :array, desc: "Delete messages at index N to M", banner: "N M"

        option :id, type: :numeric, desc: "Delete message with ID N", repeatable: true
        # @!visibility private
        def delete
          Delete
            .new(options)
            .call
        end

        desc "kill", "Kill messages in a queue"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

        option :pending, type: :boolean, desc: "Kill only pending messages (default)"
        option :processing, type: :boolean, desc: "Kill only processing messages"

        option :head, type: :numeric, desc: "Kill N messages from head of queue"
        option :tail, type: :numeric, desc: "Kill N messages from tail of queue"
        option :index, type: :numeric, desc: "Kill message at index N", repeatable: true
        option :range, type: :array, desc: "Kill messages at index N to M", banner: "N M"

        option :id, type: :numeric, desc: "Kill message with ID N", repeatable: true
        # @!visibility private
        def kill
          Kill
            .new(options)
            .call
        end

        desc "clear", "Clear messages from a queue"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

        option :pending, type: :boolean, desc: "Clear only pending messages"
        option :processing, type: :boolean, desc: "Clear only processing messages"
        option :dead, type: :boolean, desc: "Clear only dead messages"
        # @!visibility private
        def clear
          Clear
            .new(options)
            .call
        end

        desc "refill", "Refill queue (move processing messages to pending)"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true
        # @!visibility private
        def refill
          Refill
            .new(options)
            .call
        end

        desc "revive", "Revive queue (move dead messages to pending)"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true
        # @!visibility private
        def revive
          Revive
            .new(options)
            .call
        end

        desc "schedule", "Schedule failed messages for a retry"
        option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true
        # @!visibility private
        def schedule
          Schedule
            .new(options)
            .call
        end
      end
    end
  end
end
