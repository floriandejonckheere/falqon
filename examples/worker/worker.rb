#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon in a simple background job processor.
#
# The application enqueues jobs, which are picked up by a worker process.
#

require "bundler/setup"

require "falqon"

queue = Falqon::Queue.new("jobs")

puts "Waiting for jobs..."
loop do
  queue.pop do |job|
    print "Got job: #{job.inspect}... "

    # Do some work
    sleep 0.3

    # Fail sometimes
    raise RuntimeError if rand(3).zero?

    puts "Done!"
  rescue RuntimeError
    puts "Failed!"

    # Re-raise the error to re-queue the job
    raise Falqon::Error
  end
end
