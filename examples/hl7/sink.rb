#!/usr/bin/env ruby
# frozen_string_literal: true

##
# This example demonstrates how to use Falqon to build an app to convert HL7 messages to JSON.
#
# This script will parse JSON messages from the Falqon app and print them.
#

require "json"
require "socket"

server = TCPServer.new(9001)

puts "Listening on port 9001"

loop do
  socket = server.accept

  # Read message
  message = socket
    .gets("\0")
    .chomp("\0")

  # Close the connection
  socket.close

  # Parse the message
  json = JSON.parse(message)

  puts "Received admission for #{json['patient']['name']} (#{json['patient']['id']})"
end
