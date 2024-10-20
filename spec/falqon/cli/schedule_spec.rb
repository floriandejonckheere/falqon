# frozen_string_literal: true

RSpec.describe Falqon::CLI::Schedule do
  subject(:command) { described_class.new(options) }

  let(:options) { { queue: queue.name } }

  let(:queue) { build(:queue) }

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
    it "schedules the failed messages" do
      id = queue.push("message")

      # Fail processing the message
      queue.pop { raise Falqon::Error }

      # Add another message to the queue
      queue.push("another message")

      Timecop.travel(queue.retry_delay + 1) do
        # Schedule failed messages
        expect { command.call }
          .to output(/Scheduled 1 failed message for a retry/)
          .to_stdout
      end

      # Check that the message is pending
      message = Falqon::Message.new(queue, id:)
      expect(message).to be_pending

      # Check that the message is at the head of the pending queue
      expect(queue.range).to eq ["another message", "message"]
    end
  end
end
