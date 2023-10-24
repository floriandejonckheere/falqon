# frozen_string_literal: true

RSpec.describe Falqon::CLI::Status do
  subject(:command) { described_class.new(options) }

  let(:options) { {} }

  before do
    # Register queues
    queue = Falqon::Queue.new("foo")
    Falqon::Queue.new("bar")

    # Add a few entries to the queue
    queue.push("foo")
    queue.push("bar")

    5.times { queue.pop { raise Falqon::Error } }
  end

  describe "#validate" do
    context "when the given queue does not exist" do
      let(:options) { { queue: "baz" } }

      it "raises an error" do
        expect { command.validate }
          .to raise_error(/No queue registered with this name: baz/)
      end
    end

    context "when no queues are registered" do
      before { Falqon::Queue.all.each(&:delete) }

      it "raises an error" do
        expect { command.validate }
          .to raise_error(/No queues registered/)
      end
    end
  end

  describe "#execute" do
    it "prints the status of all queues" do
      expect { command.call }
        .to output(%r(foo: 1 entries \(1 pending, 0 processing, 1 dead\)))
        .to_stdout

      expect { command.call }
        .to output(%r(bar: empty))
        .to_stdout
    end

    context "when the queue option is specified" do
      let(:options) { { queue: "foo" } }

      it "prints the status of a specific queue" do
        expect { command.call }
          .to output(%r(foo))
          .to_stdout

        expect { command.call }
          .not_to output(%r(bar))
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
