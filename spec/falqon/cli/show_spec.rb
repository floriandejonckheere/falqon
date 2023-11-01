# frozen_string_literal: true

RSpec.describe Falqon::CLI::Show do
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

    context "when the --pending, --processing, and --dead options are all specified" do
      let(:options) { { queue: "queue0", pending: true, processing: true, dead: true } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--pending, --processing, and --dead are mutually exclusive/)
          .to_stdout
      end
    end

    context "when the --meta and --data options are both specified" do
      let(:options) { { queue: "queue0", meta: true, data: true } }

      it "prints an error message" do
        expect { command.call }
          .to output(/--meta and --data are mutually exclusive/)
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
    it "prints the contents of the queue" do
      expect { command.call }
        .to output(/id = 5 data = 8 bytes/)
        .to_stdout
    end

    context "when the --data option is specified" do
      let(:options) { { queue: "queue0", data: true } }

      it "prints the raw data" do
        expect { command.call }
          .to output(/message4/)
          .to_stdout
      end
    end

    context "when the --meta option is specified" do
      let(:options) { { queue: "queue0", meta: true } }

      it "prints the metadata" do
        expect { command.call }
          .to output(/id = 3 retries = 1 created_at = .* updated_at = .* data = 8 bytes/)
          .to_stdout
      end
    end

    context "when the --pending option is specified" do
      let(:options) { { queue: "queue0", pending: true } }

      it "prints the contents of the pending subqueue" do
        expect { command.call }
          .to output(/id = 5 data = 8 bytes/)
          .to_stdout
      end
    end

    context "when the --processing option is specified" do
      let(:options) { { queue: "queue0", processing: true } }

      it "prints the contents of the processing subqueue" do
        expect { command.call }
          .to output(/id = 4 data = 8 bytes/)
          .to_stdout
      end
    end

    context "when the --dead option is specified" do
      let(:options) { { queue: "queue1", dead: true } }

      it "prints the contents of the dead subqueue" do
        expect { command.call }
          .to output(/id = 1 data = 8 bytes/)
          .to_stdout
      end
    end

    describe "pagination" do
      context "when the --head option is specified" do
        let(:options) { { queue: "queue0", head: 3 } }

        it "prints the first N messages" do
          expect { command.call }
            .to output(/id = 5.*\n.*id = 6.*\n.*id = 7/)
            .to_stdout
        end
      end

      context "when the --tail option is specified" do
        let(:options) { { queue: "queue0", tail: 3 } }

        it "prints the last N messages" do
          expect { command.call }
            .to output(/id = 6.*\n.*id = 7.*\n.*id = 3/)
            .to_stdout
        end
      end

      context "when the --index option is specified" do
        let(:options) { { queue: "queue0", index: 2 } }

        it "prints the message at the given index" do
          expect { command.call }
            .to output(/id = 7/)
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
        let(:options) { { queue: "queue0", index: [1, 3] } }

        it "prints the messages at the given indices" do
          expect { command.call }
            .to output(/id = 6.*\n.*id = 3/)
            .to_stdout
        end
      end

      context "when the --range option is specified" do
        let(:options) { { queue: "queue0", range: [1, 3] } }

        it "prints the messages in the given range" do
          expect { command.call }
            .to output(/id = 6.*\n.*id = 7.*\n.*id = 3/)
            .to_stdout
        end
      end

      context "when the --id option is specified" do
        let(:options) { { queue: "queue0", id: 4 } }

        it "prints the message with the given ID" do
          expect { command.call }
            .to output(/id = 4/)
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

        it "prints the messages with the given IDs" do
          expect { command.call }
            .to output(/id = 4.*\n.*id = 6/)
            .to_stdout
        end
      end
    end
  end
end
