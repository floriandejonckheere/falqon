# frozen_string_literal: true

require "thor"

module Falqon
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "Display version"
    def version
      Version
        .new(options)
        .call
    end

    desc "queues", "Display all queues"
    def queues
      Queues
        .new(options)
        .call
    end

    desc "status", "Display queue status"
    option :queue, aliases: "-q", type: :string, desc: "Queue name"
    def status
      Status
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
    def show
      Show
        .new(options)
        .call
    end

    desc "delete", "Delete messages in a queue"
    option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

    option :pending, type: :boolean, desc: "Delete only pending messages (default)"
    option :processing, type: :boolean, desc: "Delete only processing messages"
    option :dead, type: :boolean, desc: "Delete only dead messages"

    option :head, type: :numeric, desc: "Delete N messages from head of queue"
    option :tail, type: :numeric, desc: "Delete N messages from tail of queue"
    option :index, type: :numeric, desc: "Delete message at index N", repeatable: true
    option :range, type: :array, desc: "Delete messages at index N to M", banner: "N M"

    option :id, type: :numeric, desc: "Delete message with ID N", repeatable: true
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
    def kill
      Kill
        .new(options)
        .call
    end

    desc "clear", "Clear all messages in a queue"
    option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

    option :pending, type: :boolean, desc: "Clear only pending messages"
    option :processing, type: :boolean, desc: "Clear only processing messages"
    option :dead, type: :boolean, desc: "Clear only dead messages"
    def clear
      Clear
        .new(options)
        .call
    end
  end
end
