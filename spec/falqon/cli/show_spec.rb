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

  describe "#validate" do
    context "when the given queue does not exist" do
      let(:options) { { queue: "baz" } }

      it "prints an error message" do
        expect { command.call }
          .to output(/No queue registered with this name: baz/)
          .to_stdout
      end
    end
  end

  describe "#execute" do
    it "prints the contents of the queue" do
      expect { command.call }
        .to output(/id = 2 retries = 2 created_at = .* updated_at = .* message = 3 bytes/)
        .to_stdout
    end

    context "when the --data option is specified" do
      let(:options) { { queue: "foo", data: true } }

      it "prints the raw data" do
        expect { command.call }
          .to output(/bar/)
          .to_stdout
      end
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "foo", pending: true } }

      it "prints the contents of the pending subqueue" do
        expect { command.call }
          .to output(/id = 2 retries = 2 created_at = .* updated_at = .* message = 3 bytes/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "foo", processing: true } }

      it "prints the contents of the processing subqueue" do
        expect { command.call }
          .not_to output
          .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "foo", dead: true } }

      it "prints the contents of the dead subqueue" do
        expect { command.call }
          .to output(/id = 1 retries = 0 created_at = .* updated_at = .* message = 3 bytes/)
          .to_stdout
      end
    end
  end
end
