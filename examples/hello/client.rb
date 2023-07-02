#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon in a simple microservice.
#
# The client enqueues "hello" messages, and the server responds with a "world" message.
#

require "bundler/setup"

require "falqon"

t = Thread.new do
  world = Falqon::Queue.new("world")

  loop do
    world.pop do |message|
      next unless message == "world"

      puts "Received message: #{message}"
    end
  end
end

hello = Falqon::Queue.new("hello")

puts "Sending messages..."
5.times do
  hello.push("hello")

  sleep 1
end

t.join
