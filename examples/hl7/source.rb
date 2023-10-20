#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon to build an app to convert HL7 messages to JSON.
#
# This script will generate HL7 messages and send them to the Falqon app.
#

require "socket"

message = File.read(File.join(__dir__, "adt_a01.hl7"))

loop do
  socket = TCPSocket.new("localhost", 9000)
  _, port, host, = socket.addr

  puts "Sending message from #{host}:#{port}..."

  # Write message
  socket.write(message)

  # Write null terminator
  socket.write("\0")

  socket.close

  sleep 1
end
