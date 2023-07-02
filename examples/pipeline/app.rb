#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon to build a simple data processing pipeline.
#
# This pipeline will read a file containing user account data, parse and transform
# the data, and then write it to a new file.
#

require "json"

require "bundler/setup"

require "falqon"

input_file = File.join(__dir__, "users.csv")
output_file = File.join(__dir__, "users.txt")

User = Struct.new(:first_name, :last_name, :email, :address, :phone) do
  def to_json(*_args)
    {
      first_name:,
      last_name:,
      email:,
      address:,
      phone:,
    }.to_json
  end

  def self.from_json(data)
    User.new(**JSON.parse(data))
  end
end

# Input reader thread
reader = Thread.new do
  input = Falqon::Queue.new("input")

  File.readlines(input_file).each_with_index do |line, i|
    # Skip CSV header
    next if i.zero?

    puts "Reading line #{i}"

    # Push the line onto the input queue
    input.push(line)

    sleep 0.1
  end
end

transformer = Thread.new do
  input = Falqon::Queue.new("input")
  output = Falqon::Queue.new("output")

  i = 0

  loop do
    # Read a line from the input queue
    input.pop do |line|
      puts "Processing line #{i += 1}"

      # Transform the line
      user = User.new(*line.split(","))

      # Push the transformed data onto the output queue
      output.push(user.to_json)
    end
  end
end

# Output writer thread
writer = Thread.new do
  output = Falqon::Queue.new("output")

  i = 0

  # Truncate output file
  File.write(output_file, "")

  loop do
    # Read a line from the output queue
    output.pop do |line|
      File.open(output_file, "a+") do |f|
        user = User.from_json(line)

        puts "Writing line #{i += 1}"

        # Write the line to the output file
        f.write("#{user.first_name} #{user.last_name} lives at #{user.address} and can be contacted on #{user.email} or #{user.phone}")
      end
    end
  end
end

# Wait only for the reader thread to finish
reader.join

# Wait for the transformer and writer threads to complete their work
sleep 0.1

# Stop the transformer and writer threads
transformer.kill
writer.kill

puts "Exiting..."
