# frozen_string_literal: true

RSpec.describe Falqon::CLI::Delete do
  subject(:command) { described_class.new(options) }

  let(:options) { { queue: "foo" } }

  before do
    # Register queues
    queue = Falqon::Queue.new("foo")

    # Add a few entries to the queue
    queue.push("foo")
    queue.push("bar")
    queue.push("baz")
    queue.push("bat")
    queue.push("bak")
    queue.push("baq")

    13.times { queue.pop { raise Falqon::Error } }
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

    context "when the --pending, --processing, and --dead options are all specified" do
      let(:options) { { queue: "foo", pending: true, processing: true, dead: true } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--pending, --processing, and --dead are mutually exclusive/)
          .to_stdout
      end
    end

    context "when the --head, --tail, --index, and --range options are all specified" do
      let(:options) { { queue: "foo", head: 3, tail: 3, index: 3, range: [3, 5] } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--head, --tail, --index, and --range are mutually exclusive/)
          .to_stdout
      end
    end

    context "when the --range option is specified with an invalid number of arguments" do
      let(:options) { { queue: "foo", range: [1] } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--range must be specified as two integers/)
          .to_stdout
      end
    end

    context "when the --id option is specified with --head, --tail, --index, or --range" do
      let(:options) { { queue: "foo", id: 1, head: 3 } }

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
        .to output(/Deleted 5 entries from queue foo/)
        .to_stdout
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "foo", pending: true } }

      it "clears the pending entries" do
        expect { command.call }
          .to output(/Deleted 5 pending entries from queue foo/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "foo", processing: true } }

      it "clears the processing entries" do
        expect { command.call }
          .to output(/Deleted 0 processing entries from queue foo/)
          .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "foo", dead: true } }

      it "clears the dead entries" do
        expect { command.call }
          .to output(/Deleted 1 dead entry from queue foo/)
          .to_stdout
      end
    end

    describe "pagination" do
      context "when the --head option is specified" do
        let(:options) { { queue: "foo", head: 3 } }

        it "deletes the first N entries" do
          expect { command.call }
            .to output(/Deleted 3 entries from queue foo/) # id = 1 is in the dead queue
            .to_stdout
        end
      end

      context "when the --tail option is specified" do
        let(:options) { { queue: "foo", tail: 3 } }

        it "deletes the last N entries" do
          expect { command.call }
            .to output(/Deleted 3 entries from queue foo/)
            .to_stdout
        end
      end

      context "when the --index option is specified" do
        let(:options) { { queue: "foo", index: 2 } }

        it "deletes the entry at the given index" do
          expect { command.call }
            .to output(/Deleted 1 entry from queue foo/) # id = 1 is in the dead queue
            .to_stdout
        end

        context "when the index does not exist" do
          let(:options) { { queue: "foo", index: 100 } }

          it "prints an error message" do
            expect { command.call }
              .to output(/No entry at index 100/)
              .to_stdout
          end
        end
      end

      context "when the --index option is specified multiple times" do
        let(:options) { { queue: "foo", index: [2, 4] } }

        it "deletes the entries at the given indices" do
          expect { command.call }
            .to output(/Deleted 2 entries from queue foo/) # id = 1 is in the dead queue
            .to_stdout
        end
      end

      context "when the --range option is specified" do
        let(:options) { { queue: "foo", range: [2, 4] } }

        it "deletes the entries in the given range" do
          expect { command.call }
            .to output(/Deleted 3 entries from queue foo/) # id = 1 is in the dead queue
            .to_stdout
        end
      end

      context "when the --id option is specified" do
        let(:options) { { queue: "foo", id: 4 } }

        it "deletes the entry with the given ID" do
          expect { command.call }
            .to output(/Deleted 1 entry from queue foo/)
            .to_stdout
        end

        context "when the ID does not exist" do
          let(:options) { { queue: "foo", id: 100 } }

          it "prints an error message" do
            expect { command.call }
              .to output(/No entry with ID 100/)
              .to_stdout
          end
        end
      end

      context "when the --id option is specified multiple times" do
        let(:options) { { queue: "foo", id: [4, 6] } }

        it "deletes the entries with the given IDs" do
          expect { command.call }
            .to output(/Deleted 2 entries from queue foo/)
            .to_stdout
        end
      end
    end
  end
end
