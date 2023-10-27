# frozen_string_literal: true

RSpec.shared_context "with a couple of queues" do
  ##
  # This context creates a couple of queues, pushes a few entries and then (fails to) process the entries a few times
  #
  # The result of the block:
  #   foo (5 pending, 0 processing, 1 dead)
  #     pending: [2, 3, 4, 5, 6]
  #     processing: []
  #     dead: [1]
  #   bar (0 pending, 0 processing, 0 dead)
  #
  before do
    # Register queues
    foo = Falqon::Queue.new("foo")
    Falqon::Queue.new("bar")

    # Add a few entries
    foo.push("foo")
    foo.push("bar")
    foo.push("baz")
    foo.push("bat")
    foo.push("bak")
    foo.push("baq")

    # Process and kill a few entries
    13.times { foo.pop { raise Falqon::Error } }
  end
end
