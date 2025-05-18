# frozen_string_literal: true

require "thor"

module Falqon
  # Falqon includes a command-line interface (CLI) to manage queues and messages
  #
  # After installing Falqon, run +falqon+ to see the available commands.
  #
  #   $ falqon
  #   Commands:
  #     falqon help [COMMAND]  # Describe available commands or one specific command
  #     falqon status          # Print queue status
  #     falqon version         # Print version
  #
  # To see the available options for a command, run +falqon help COMMAND+.
  # The command-line interface assumes the default Falqon configuration.
  # To use a custom configuration, set the corresponding environment variables:
  #
  #   # Configure global queue name prefix
  #   FALQON_PREFIX=falqon
  #
  #   # Configure Redis connection pool
  #   REDIS_URL=redis://localhost:6379/0
  #
  class CLI < Thor
    # @!visibility private
    def self.exit_on_failure?
      true
    end

    include Falqon::Commands

    begin
      require "falqon/pro"
      require "falqon/pro/commands"

      include Falqon::Pro::Commands
    rescue LoadError
      nil
    end
  end
end
