#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon in a simple background job processor.
#
# The application enqueues jobs, which are picked up by a worker thread.
#

require "json"

require "bundler/setup"

require "falqon"

logger = Logger.new($stdout)
logger.formatter = proc do |severity, datetime, _progname, msg|
  "[#{datetime.strftime("%Y-%m-%d %H:%M:%S")}] #{severity}: #{msg}\n"
end

# Start an application thread
app = Thread.new do
  queue = Falqon::Queue.new("jobs")

  logger.info "[app] Enqueueing jobs..."

  i = 0
  loop do
    logger.info "[app] Enqueueing job #{i}..."

    data = {
      id: i,
      time: Time.now.to_i,
      sleep: rand(0.4..0.5),
      data: {
        user: {
          id: rand(1000),
          name: "User #{rand(1000)}",
          email: "user#{rand(1000)}@localhost",
        },
        message: "Hello, w#{rand(10).zero? ? 'o' * 1000 : 'o'}rld!",
        system: {
          pid: Process.pid,
          hostname: Socket.gethostname,
          uptime: `uptime`.chomp,
        },
      },
    }

    queue.push(data.to_json)

    i += 1

    sleep rand(0.4..0.5)
  end
end

# Start a worker thread
worker = Thread.new do

  queue = Falqon::Queue.new("jobs")

  logger.info "[worker] Waiting for jobs..."
  loop do
    queue.pop do |job|
      data = JSON.parse(job, symbolize_names: true)

      logger.info "[worker] Received job #{data[:id]}... "

      # Do some work
      sleep data[:sleep]

      # Fail sometimes
      raise RuntimeError if rand(3).zero?

      logger.info "[worker] Job #{data[:id]} completed!"
    rescue RuntimeError
      logger.error "[worker] Job #{data[:id]} failed!"

      # Re-raise the error to re-queue the job
      raise Falqon::Error
    end
  end
end

# Wait for the threads to finish
app.join
worker.join
