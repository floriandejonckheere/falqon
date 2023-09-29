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

    it "sets the entry status to dead" do
      id = queue.push("message1")

      queue.pop { raise Falqon::Error }

      entry = Falqon::Entry.new(queue, id:)

      expect(entry.metadata.status).to eq "dead"
    end
  end
end
