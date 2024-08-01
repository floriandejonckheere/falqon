# frozen_string_literal: true

RSpec.describe Falqon::CLI::Delete do
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

    context "when the --head, --tail, --index, and --range options are all specified" do
      let(:options) { { queue: "queue0", head: 3, tail: 3, index: 3, range: [3, 5] } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--head, --tail, --index, and --range are mutually exclusive/)
          .to_stdout
      end
    end

    context "when the --range option is specified with an invalid number of arguments" do
      let(:options) { { queue: "queue0", range: [1] } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--range must be specified as two integers/)
          .to_stdout
      end
    end

    context "when the --id option is specified with --head, --tail, --index, or --range" do
      let(:options) { { queue: "queue0", id: 1, head: 3 } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--id is mutually exclusive with --head, --tail, --index, and --range/)
          .to_stdout
      end
    end
  end

  describe "#execute" do
    it "deletes the contents of the queue" do
      expect { command.call }
        .to output(/Deleted 3 pending messages from queue queue0/)
        .to_stdout
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "queue0", pending: true } }

      it "deletes the pending messages" do
        expect { command.call }
          .to output(/Deleted 3 pending messages from queue queue0/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "queue0", processing: true } }

      it "deletes the processing messages" do
        expect { command.call }
          .to output(/Deleted 1 processing message from queue queue0/)
          .to_stdout
      end
    end

    context "when the --scheduled option is specified" do
      let(:options) { { queue: "queue0", scheduled: true } }

      it "deletes the scheduled messages" do
        expect { command.call }
          .to output(/Deleted 1 scheduled message from queue queue0/)
          .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "queue1", dead: true } }

      it "deletes the dead messages" do
        expect { command.call }
          .to output(/Deleted 2 dead messages from queue queue1/)
          .to_stdout
      end
    end

    describe "pagination" do
      context "when the --head option is specified" do
        let(:options) { { queue: "queue0", head: 2 } }

        it "deletes the first N messages" do
          expect { command.call }
            .to output(/Deleted 2 pending messages from queue queue0/)
            .to_stdout
        end
      end

      context "when the --tail option is specified" do
        let(:options) { { queue: "queue0", tail: 2 } }

        it "deletes the last N messages" do
          expect { command.call }
            .to output(/Deleted 2 pending messages from queue queue0/)
            .to_stdout
        end
      end

      context "when the --index option is specified" do
        let(:options) { { queue: "queue0", index: 2 } }

        it "deletes the message at the given index" do
          expect { command.call }
            .to output(/Deleted 1 pending message from queue queue0/)
            .to_stdout
        end

        context "when the index does not exist" do
          let(:options) { { queue: "queue0", index: 100 } }

          it "prints an error message" do
            expect { command.call }
              .to output(/No message at index 100/)
              .to_stdout
          end
        end
      end

      context "when the --index option is specified multiple times" do
        let(:options) { { queue: "queue0", index: [0, 1] } }

        it "deletes the messages at the given indices" do
          expect { command.call }
            .to output(/Deleted 2 pending messages from queue queue0/)
            .to_stdout
        end
      end

      context "when the --range option is specified" do
        let(:options) { { queue: "queue0", range: [0, 2] } }

        it "deletes the messages in the given range" do
          expect { command.call }
            .to output(/Deleted 3 pending messages from queue queue0/)
            .to_stdout
        end
      end

      context "when the --id option is specified" do
        let(:options) { { queue: "queue0", id: 4 } }

        it "deletes the message with the given ID" do
          expect { command.call }
            .to output(/Deleted 1 pending message from queue queue0/)
            .to_stdout
        end

        context "when the ID does not exist" do
          let(:options) { { queue: "queue0", id: 100 } }

          it "prints an error message" do
            expect { command.call }
              .to output(/No message with ID 100/)
              .to_stdout
          end
        end
      end

      context "when the --id option is specified multiple times" do
        let(:options) { { queue: "queue0", id: [4, 6] } }

        it "deletes the messages with the given IDs" do
          expect { command.call }
            .to output(/Deleted 2 pending messages from queue queue0/)
            .to_stdout
        end
      end
    end
  end
end
