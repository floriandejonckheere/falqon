# frozen_string_literal: true

RSpec.describe Falqon::Strategies::None do
  subject(:queue) { Falqon::Queue.new("name", retry_strategy: :none) }

  describe "#retry" do
    it "removes the identifier from the processing queue" do
      queue.push("message1")

      queue.pop { raise Falqon::Error }

      expect(queue.pending).to be_empty
      expect(queue.processing).to be_empty
      expect(queue.dead).not_to be_empty
    end

    it "sets the message metadata" do
      id = queue.push("message1")

      Timecop.freeze do
        queue.pop { raise Falqon::Error, "An error occurred" }

        message = Falqon::Message.new(queue, id:)

        expect(message.metadata.status).to eq "dead"

        expect(message.metadata.retried_at).to eq Time.now.to_i
        expect(message.metadata.retry_error).to eq "An error occurred"
      end
    end
  end
end
