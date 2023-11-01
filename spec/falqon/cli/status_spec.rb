# frozen_string_literal: true

RSpec.describe Falqon::CLI::Status do
  subject(:command) { described_class.new(options) }

  let(:options) { {} }

  describe "#validate" do
    context "when the given queue does not exist" do
      let(:options) { { queue: "notfound" } }

      it "raises an error" do
        expect { command.validate }
          .to raise_error(/No queue registered with this name: notfound/)
      end
    end

    context "when no queues are registered" do
      before { Falqon.redis.with(&:flushdb) }

      it "raises an error" do
        expect { command.validate }
          .to raise_error(/No queues registered/)
      end
    end
  end

  describe "#execute" do
    it "prints the status of all queues" do
      expect { command.call }
        .to output(/queue0: 4 pending, 1 processing, 0 dead/)
        .to_stdout

      expect { command.call }
        .to output(/queue1: 0 pending, 0 processing, 2 dead/)
        .to_stdout

      expect { command.call }
        .to output(/queue2: empty/)
        .to_stdout
    end

    context "when the queue option is specified" do
      let(:options) { { queue: "queue0" } }

      it "prints the status of a specific queue" do
        expect { command.call }
          .to output(/queue0:/)
          .to_stdout

        expect { command.call }
          .not_to output(/queue1:/)
          .to_stdout
      end

      context "when the given queue does not exist" do
        let(:options) { { queue: "notfound" } }

        it "prints an error message" do
          expect { command.call }
            .to output(/No queue registered with this name: notfound/)
            .to_stdout
        end
      end
    end
  end
end
