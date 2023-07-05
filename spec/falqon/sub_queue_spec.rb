# frozen_string_literal: true

RSpec.describe Falqon::SubQueue do
  subject(:sub_queue) { described_class.new(queue, name) }

  let(:queue) { Falqon::Queue.new("name") }
  let(:name) { "subname" }

  describe "#name" do
    it "appends a suffix" do
      expect(sub_queue.name).to eq "falqon/name:subname"
    end

    context "when no name is configured" do
      let(:name) { nil }

      it "does not append a suffix" do
        expect(sub_queue.name).to eq "falqon/name"
      end
    end
  end

  describe "#add" do
    it "adds an identifier to the queue" do
      sub_queue.add(1)

      queue.redis.with do |r|
        expect(r.lrange("falqon/name:subname", 0, -1)).to eq ["1"]
      end
    end
  end

  describe "#remove" do
    it "removes an identifier from the queue" do
      sub_queue.add(1)
      sub_queue.remove(1)

      queue.redis.with do |r|
        expect(r.lrange("falqon/name:subname", 0, -1)).to eq []
      end
    end
  end

  describe "#peek" do
    it "returns the first identifier in the queue" do
      sub_queue.add(1)
      sub_queue.add(2)

      expect(sub_queue.peek).to eq 1
    end

    context "when the queue is empty" do
      it "returns nil" do
        expect(sub_queue.peek).to be_nil
      end
    end
  end

  describe "clear" do
    it "clears the queue" do
      sub_queue.add(1)
      sub_queue.add(2)
      sub_queue.clear

      queue.redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys - ["falqon:queues", "falqon/name:stats"]).to be_empty
      end
    end

    it "returns the deleted messages' identifiers" do
      sub_queue.add(1)
      sub_queue.add(2)

      expect(sub_queue.clear).to eq [1, 2]
    end

    context "when the queue is empty" do
      it "returns an empty array" do
        expect(sub_queue.clear).to be_empty
      end
    end
  end

  describe "#size" do
    it "returns the size of the queue" do
      sub_queue.add(1)
      sub_queue.add(2)

      expect(sub_queue.size).to eq 2
    end

    context "when the queue is empty" do
      it "returns 0" do
        expect(sub_queue.size).to eq 0
      end
    end
  end
end
