# frozen_string_literal: true

require "thor"

module Falqon
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "Print version"
    def version
      Version
        .new(options)
        .call
    end

    desc "status", "Print queue status"
    option :queue, aliases: "-q", type: :string, desc: "Queue name"
    def status
      Status
        .new(options)
        .call
    end

    desc "show", "Show queue contents"
    option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

    option :pending, type: :boolean, desc: "Display pending entries (default)"
    option :processing, type: :boolean, desc: "Display processing entries"
    option :dead, type: :boolean, desc: "Display dead entries"

    option :data, aliases: "-d", type: :boolean, desc: "Display raw data"
    option :meta, aliases: "-m", type: :boolean, desc: "Display additional metadata"

    option :head, type: :numeric, desc: "Display N entries from head of queue"
    option :tail, type: :numeric, desc: "Display N entries from tail of queue"
    option :index, type: :numeric, desc: "Display entry at index N"
    option :range, type: :array, desc: "Display entries at index N to M", banner: "N M"

    option :id, type: :numeric, desc: "Display entry with ID N"
    def show
      Show
        .new(options)
        .call
    end

    desc "clear", "Clear queue"
    option :queue, aliases: "-q", type: :string, desc: "Queue name", required: true

    option :pending, type: :boolean, desc: "Clear only pending entries"
    option :processing, type: :boolean, desc: "Clear only processing entries"
    option :dead, type: :boolean, desc: "Clear only dead entries"
    def clear
      Clear
        .new(options)
        .call
    end
  end
end
