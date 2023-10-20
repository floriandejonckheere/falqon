#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon to build an app to convert
# HL7 ADT A01 messages to JSON.
#
# This script will wait for connections from a HL7 source, parse and
# transform HL7 messages and send them to the JSON sink.
#

require "json"
require "socket"
require "time"

require "bundler/setup"

require "falqon"

# TCP server thread
server = Thread.new do
  hl7 = Falqon::Queue.new("hl7")

  tcp_server = TCPServer.new(9000)

  puts "Listening on port 9000"

  loop do
    socket = tcp_server.accept
    _, port, host, = socket.peeraddr

    puts "Connected: #{host}:#{port}"

    # Read message
    message = socket
      .gets("\0")
      .chomp("\0")

    puts "Received message from #{host}:#{port}"

    # Push the data onto the queue
    hl7.push(message)

    # Close the connection
    socket.close
  end
end

# HL7 parser thread
Thread.new do
  hl7 = Falqon::Queue.new("hl7")
  json = Falqon::Queue.new("json")

  # Read messages from the queue
  loop do
    hl7.pop do |message|
      puts "Parsing message..."

      # Parse the message
      parsed_message = message
        .split("\r")
        .map { |l| l.split("|") }
        .to_h { |segment, *fields| [segment.to_sym, fields] }

      # Transform the message
      json_message = {
        source: parsed_message[:MSH][1],
        patient: {
          name: parsed_message[:PID][4].split("^").reject { |s| s == "" }.reverse.join(" "),
          id: parsed_message[:PID][2].to_s,
        },
        visit: {
          date_time: Time.parse(parsed_message[:EVN][1]).to_s,
        },
      }.to_json

      # Push the transformed message onto the queue
      json.push(json_message)
    end
  end
end

# Dispatcher thread
Thread.new do
  json = Falqon::Queue.new("json")

  loop do
    json.pop do |message|
      socket = TCPSocket.new("localhost", 9001)
      _, port, host, = socket.addr

      puts "Sending message from #{host}:#{port}..."

      # Write message
      socket.write(message)

      # Write null terminator
      socket.write("\0")

      socket.close
    end
  end
end

server.join
