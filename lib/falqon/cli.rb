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
    def show
      Show
        .new(options)
        .call
    end
  end
end
