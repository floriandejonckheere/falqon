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
    def show
      Show
        .new(options)
        .call
    end
  end
end
