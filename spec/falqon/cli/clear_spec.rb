# frozen_string_literal: true

RSpec.describe Falqon::CLI::Clear do
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

    context "when the --pending, --processing, --scheduled, and --dead options are all specified" do
      let(:options) { { queue: "queue0", pending: true, processing: true, scheduled: true, dead: true } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--pending, --processing, --scheduled, and --dead are mutually exclusive/)
          .to_stdout
      end
    end
  end

  describe "#execute" do
    it "clears the queue" do
      expect { command.call }
        .to output(/Cleared 5 messages from queue queue0/)
        .to_stdout
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "queue0", pending: true } }

      it "clears the pending messages" do
        expect { command.call }
          .to output(/Cleared 4 pending messages from queue queue0/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "queue0", processing: true } }

      it "clears the processing messages" do
        expect { command.call }
          .to output(/Cleared 1 processing message from queue queue0/)
          .to_stdout
      end
    end

    context "when the --scheduled option is specified" do
      let(:options) { { queue: "queue0", scheduled: true } }

      it "clears the scheduled messages" do
        expect { command.call }
          .to output(/Cleared 0 scheduled messages from queue queue0/)
                .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "queue1", dead: true } }

      it "clears the dead messages" do
        expect { command.call }
          .to output(/Cleared 2 dead messages from queue queue1/)
          .to_stdout
      end
    end
  end
end
