#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon in a simple microservice.
#
# The client enqueues "hello" messages, and the server responds with a "world" message.
#

require "bundler/setup"

require "falqon"

hello = Falqon::Queue.new("hello")
world = Falqon::Queue.new("world")

puts "Waiting for messages..."
loop do
  hello.pop do |message|
    next unless message == "hello"

    puts "Received message: #{message}"

    world.push("world")
  end
end
