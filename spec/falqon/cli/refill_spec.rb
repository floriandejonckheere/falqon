# frozen_string_literal: true

RSpec.describe Falqon::CLI::Refill do
  subject(:command) { described_class.new(options) }

  let(:options) { { queue: "queue0" } }

  describe "#validate" do
    context "when the given queue does not exist" do
      let(:options) { { queue: "notfound" } }

      it "prints an error message" do
        expect { command.call }
          .to output(/No queue registered with this name: notfound/)
          .to_stdout
      end
    end
  end

  describe "#execute" do
    it "refills the queue" do
      expect { command.call }
        .to output(/Refilled 1 message in queue queue0/)
        .to_stdout
    end
  end
end
