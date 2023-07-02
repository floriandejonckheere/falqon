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

puts "Enqueueing jobs..."
10.times do |i|
  puts "Enqueueing job #{i}..."
  queue.push("job #{i}")

  sleep rand(0..0.5)
end
