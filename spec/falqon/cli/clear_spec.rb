# frozen_string_literal: true

RSpec.describe Falqon::CLI::Clear do
  subject(:command) { described_class.new(options) }

  include_context "with a couple of queues"

  let(:options) { { queue: "foo" } }

  describe "#validate" do
    context "when the given queue does not exist" do
      let(:options) { { queue: "baz" } }

      it "prints an error message" do
        expect { command.call }
          .to output(/No queue registered with this name: baz/)
          .to_stdout
      end
    end

    context "when the --pending, --processing, and --dead options are all specified" do
      let(:options) { { queue: "foo", pending: true, processing: true, dead: true } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--pending, --processing, and --dead are mutually exclusive/)
          .to_stdout
      end
    end
  end

  describe "#execute" do
    it "clears the queue" do
      expect { command.call }
        .to output(/Cleared 6 entries from queue foo/)
        .to_stdout
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "foo", pending: true } }

      it "clears the pending entries" do
        expect { command.call }
          .to output(/Cleared 5 pending entries from queue foo/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "foo", processing: true } }

      it "clears the processing entries" do
        expect { command.call }
          .to output(/Cleared 0 processing entries from queue foo/)
          .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "foo", dead: true } }

      it "clears the dead entries" do
        expect { command.call }
          .to output(/Cleared 1 dead entry from queue foo/)
          .to_stdout
      end
    end
  end
end
