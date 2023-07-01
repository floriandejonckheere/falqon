# frozen_string_literal: true

RSpec.describe Falqon::SubQueue do
  subject(:sub_queue) { described_class.new(queue, name) }

  let(:queue) { Falqon::Queue.new("name") }
  let(:name) { "subname" }

  describe "#name" do
    it "appends a suffix" do
      expect(sub_queue.name).to eq sub_queue.name
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
      sub_queue.add("message1")

      queue.redis.with do |r|
        expect(r.lrange(sub_queue.name, 0, -1)).to eq ["1"]
      end
    end

    it "returns an identifier" do
      expect(sub_queue.add("message1")).to eq 1
    end

    it "adds multiple identifiers to the queue" do
      sub_queue.add("message1", "message2")

      queue.redis.with do |r|
        expect(r.lrange(sub_queue.name, 0, -1)).to eq ["1", "2"]
      end
    end

    it "returns multiple identifiers" do
      expect(sub_queue.add("message1", "message2")).to eq [1, 2]
    end
  end

  describe "#move" do
    let(:other) { described_class.new(queue, "other") }

    it "moves an identifier from one queue to another" do
      sub_queue.add("message1", "message2")
      sub_queue.move(other)

      queue.redis.with do |r|
        expect(r.lrange(sub_queue.name, 0, -1)).to eq ["2"]
        expect(r.lrange(other.name, 0, -1)).to eq ["1"]
      end
    end

    it "returns the identifier and message" do
      sub_queue.add("message1", "message2")

      expect(sub_queue.move(other)).to eq [1, "message1"]
    end
  end

  describe "#remove" do
    it "removes an identifier from the queue" do
      id = sub_queue.add("message1")
      sub_queue.remove(id)

      queue.redis.with do |r|
        expect(r.lrange(sub_queue.name, 0, -1)).to eq []
      end
    end
  end

  describe "#peek" do
    it "returns the first identifier in the queue" do
      sub_queue.add("message1", "message2")

      expect(sub_queue.peek).to eq "message1"
    end

    context "when the queue is empty" do
      it "returns nil" do
        expect(sub_queue.peek).to be_nil
      end
    end
  end

  describe "clear" do
    it "clears the queue" do
      sub_queue.add("message1", "message2")

      sub_queue.clear

      queue.redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys).to be_empty
      end
    end

    it "returns the deleted messages' identifiers" do
      sub_queue.add("message1", "message2")

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
      sub_queue.add("message1", "message2")

      expect(sub_queue.size).to eq 2
    end

    context "when the queue is empty" do
      it "returns 0" do
        expect(sub_queue.size).to eq 0
      end
    end
  end
end
