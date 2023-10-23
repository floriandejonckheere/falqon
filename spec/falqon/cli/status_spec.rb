# frozen_string_literal: true

RSpec.describe Falqon::CLI::Status do
  subject(:command) { described_class.new(options) }

  let(:options) { {} }

  context "when no queues are registered" do
    it "prints an error message" do
      expect { command.call }
        .to output("No queues registered\n")
        .to_stdout
    end
  end

  context "when a queue is registered" do
    before do
      # Register queues
      queue = Falqon::Queue.new("foo")
      Falqon::Queue.new("bar")

      # Add a few entries to the queue
      queue.push("foo")
      queue.push("bar")

      5.times { queue.pop { raise Falqon::Error } }
    end

    it "prints the status of all queues" do
      expect { command.call }
        .to output(%r(falqon/foo: 1 entries \(1 pending, 0 processing, 1 dead\)))
        .to_stdout

      expect { command.call }
        .to output(%r(falqon/bar: empty))
        .to_stdout
    end

    context "when the queue option is specified" do
      let(:options) { { queue: "foo" } }

      it "prints the status of a specific queue" do
        expect { command.call }
          .to output(%r(falqon/foo))
          .to_stdout

        expect { command.call }
          .not_to output(%r(falqon/bar))
          .to_stdout
      end

      context "when the given queue does not exist" do
        let(:options) { { queue: "baz" } }

        it "prints an error message" do
          expect { command.call }
            .to output(/No queue registered with this name: baz/)
            .to_stdout
        end
      end
    end
  end
end
