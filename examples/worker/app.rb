#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon in a simple background job processor.
#
# The application enqueues jobs, which are picked up by a worker process.
#

require "json"

require "bundler/setup"

require "falqon"

queue = Falqon::Queue.new("jobs")

puts "Enqueueing jobs..."

i = 0
loop do
  puts "Enqueueing job #{i}..."

  data = { id: i, time: Time.now.to_i, sleep: rand(0.4..0.5) }
  data[:long] = "x" * 1024 if rand(10).zero?

  queue.push(data.to_json)

  i += 1

  sleep rand(0.4..0.5)
end
