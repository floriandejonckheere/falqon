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
  end
end
