# frozen_string_literal: true

RSpec.describe Falqon::Queue do
  subject(:queue) { described_class.new("name") }

  describe "#push" do
    it "pushes items to the queue" do
      queue.push("item1", "item2")

      expect(queue.pop).to eq("item1")
      expect(queue.pop).to eq("item2")
    end
  end

  describe "#pop" do
    it "pops items from the queue" do
      queue.push("item1", "item2")

      expect(queue.pop).to eq("item1")
      expect(queue.pop).to eq("item2")
    end
  end
end
