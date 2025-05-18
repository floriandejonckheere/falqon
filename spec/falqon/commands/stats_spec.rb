# frozen_string_literal: true

RSpec.describe Falqon::Commands::Stats do
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
    it "prints the statistics of all queues" do
      expect { command.call }
        .to output(/queue0: 5 processed, 2 failed, 0 retried \(created: .*, updated: .*\)/)
        .to_stdout

      expect { command.call }
        .to output(/queue1: 4 processed, 4 failed, 2 retried \(created: .*, updated: .*\)/)
        .to_stdout

      expect { command.call }
        .to output(/queue2: 0 processed, 0 failed, 0 retried \(created: .*, updated: .*\)/)
        .to_stdout
    end

    context "when the queue option is specified" do
      let(:options) { { queue: "queue0" } }

      it "prints the statistics of a specific queue" do
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
