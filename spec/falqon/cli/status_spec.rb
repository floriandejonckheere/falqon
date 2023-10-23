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
    before { Falqon::Queue.new("test") }

    it "prints the status of all queues" do
      expect { command.call }
        .to output("falqon/test: 0 entries\n")
        .to_stdout
    end

    context "when the queue option is specified" do
      let(:options) { { queue: "test" } }

      it "prints the status of a specific queue" do
        expect { command.call }
          .to output("falqon/test: 0 entries\n")
          .to_stdout
      end

      context "when the given queue does not exist" do
        let(:options) { { queue: "foo" } }

        it "prints an error message" do
          expect { command.call }
            .to output("No queue registered with this name: foo\n")
            .to_stdout
        end
      end
    end
  end
end
