# frozen_string_literal: true

RSpec.describe Falqon::SubQueue do
  subject(:sub_queue) { described_class.new(queue, type) }

  let(:queue) { Falqon::Queue.new("name") }
  let(:type) { "subname" }

  before { Falqon.redis.with(&:flushdb) }

  describe "#id" do
    it "appends a suffix" do
      expect(sub_queue.id).to eq "falqon/name:subname"
    end

    context "when no type is configured" do
      let(:type) { nil }

      it "does not append a suffix" do
        expect(sub_queue.id).to eq "falqon/name"
      end
    end
  end

  describe "#add" do
    it "adds an identifier to the tail of the queue" do
      sub_queue.add(1)
      sub_queue.add(2)

      expect(sub_queue.peek(index: 0)).to eq 1
      expect(sub_queue.peek(index: 1)).to eq 2
    end

    it "adds an identifier to the head of the queue" do
      sub_queue.add(1)
      sub_queue.add(2, head: true)

      expect(sub_queue.peek(index: 0)).to eq 2
      expect(sub_queue.peek(index: 1)).to eq 1
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

    it "returns the nth identifier in the queue" do
      sub_queue.add(1)
      sub_queue.add(2)
      sub_queue.add(3)

      expect(sub_queue.peek(index: 0)).to eq 1
      expect(sub_queue.peek(index: 1)).to eq 2
      expect(sub_queue.peek(index: 2)).to eq 3
    end

    context "when the queue is empty" do
      it "returns nil" do
        expect(sub_queue.peek).to be_nil
      end
    end
  end

  describe "#range" do
    it "returns the identifiers in the queue" do
      sub_queue.add(1)
      sub_queue.add(2)
      sub_queue.add(3)

      expect(sub_queue.range).to eq [1, 2, 3]
    end

    it "returns the identifiers in the queue in the given range" do
      sub_queue.add(1)
      sub_queue.add(2)
      sub_queue.add(3)

      expect(sub_queue.range(start: 1)).to eq [2, 3]
      expect(sub_queue.range(start: 1, stop: 1)).to eq [2]
      expect(sub_queue.range(start: 1, stop: 2)).to eq [2, 3]
      expect(sub_queue.range(stop: 1)).to eq [1, 2]
    end

    context "when the queue is empty" do
      it "returns an empty array" do
        expect(sub_queue.range).to be_empty
      end
    end
  end

  describe "#clear" do
    it "clears the queue" do
      sub_queue.add(1)
      sub_queue.add(2)
      sub_queue.clear

      queue.redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys - ["falqon:queues", "falqon/name:metadata"]).to be_empty
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

  describe "#empty?" do
    it "returns false" do
      sub_queue.add(1)

      expect(sub_queue).not_to be_empty
    end

    context "when the queue is empty" do
      it "returns true" do
        expect(sub_queue).to be_empty
      end
    end
  end

  describe "#to_a" do
    it "returns the identifiers in the queue" do
      sub_queue.add(1)
      sub_queue.add(2)

      expect(sub_queue.to_a).to eq [1, 2]
    end
  end
end
