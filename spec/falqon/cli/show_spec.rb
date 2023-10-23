# frozen_string_literal: true

RSpec.describe Falqon::CLI::Show do
  subject(:command) { described_class.new(options) }

  let(:options) { { queue: "foo" } }

  before do
    # Register queues
    queue = Falqon::Queue.new("foo")

    # Add a few entries to the queue
    queue.push("foo")
    queue.push("bar")

    5.times { queue.pop { raise Falqon::Error } }
  end

  context "when the given queue does not exist" do
    let(:options) { { queue: "baz" } }

    it "prints an error message" do
      expect { command.call }
        .to output(/No queue registered with this name: baz/)
        .to_stdout
    end
  end

  it "prints the contents of the queue" do
    expect { command.call }
      .to output(/id = 2 retries = 2 created_at = .* updated_at = .* message = 3 bytes/)
      .to_stdout
  end
end
