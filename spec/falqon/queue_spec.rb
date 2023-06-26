# frozen_string_literal: true

RSpec.describe Falqon::Queue do
  subject(:queue) { described_class.new("name") }

  it "has a prefix" do
    expect(queue.name).to eq "falqon/name"
  end

  describe "#push" do
    it "pushes items to the queue" do
      queue.push("item1", "item2")

      expect { |b| queue.pop(&b) }.to yield_with_args("item1")
      expect { |b| queue.pop(&b) }.to yield_with_args("item2")
    end

    it "returns the pushed items' identifiers" do
      id1, id2 = queue.push("item1", "item2")

      expect(id1).to eq 1
      expect(id2).to eq 2
    end
  end

  describe "#pop" do
    it "pops an item from the queue and returns it" do
      queue.push("item1", "item2")

      expect(queue.pop).to eq "item1"
      expect(queue.pop).to eq "item2"
    end

    context "when the queue is empty" do
      it "blocks until an item is pushed to the queue" do
        expect { queue.pop }.to raise_error MockRedis::WouldBlock
      end
    end

    context "when a block is given" do
      it "pops an item from the queue and yields it" do
        queue.push("item1", "item2")

        expect { |b| queue.pop(&b) }.to yield_with_args("item1")
        expect { |b| queue.pop(&b) }.to yield_with_args("item2")
      end

      it "requeues items if they fail" do
        queue.push("item1", "item2")

        queue.pop { raise Falqon::Error }

        expect { |b| queue.pop(&b) }.to yield_with_args("item2")
        expect { |b| queue.pop(&b) }.to yield_with_args("item1")
      end

      it "discards items if they fail too many times" do
        queue.push("item1")

        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }

        expect { |b| queue.pop(&b) }.to raise_error MockRedis::WouldBlock

        # TODO: Check that the item has been moved to the dead queue
        # TODO: Check that the retry count has been reset
        expect(queue).to be_empty
      end

      context "when the queue is empty" do
        it "blocks until an item is pushed to the queue" do
          expect { |b| queue.pop(&b) }.to raise_error MockRedis::WouldBlock
        end
      end
    end
  end

  describe "#clear" do
    it "clears the queue" do
      queue.push("item1", "item2")

      queue.clear

      expect(queue).to be_empty

      # Check that all keys have been deleted
      expect(Falqon.redis.with(&:keys)).to be_empty
    end

    it "returns the number of deleted items" do
      queue.push("item1", "item2")

      expect(queue.clear).to eq 2
    end
  end

  describe "#size" do
    it "returns the size of the queue" do
      queue.push("item1", "item2")

      expect(queue.size).to eq 2
    end
  end

  describe "#empty?" do
    it "returns true if the queue is empty" do
      expect(queue).to be_empty
    end

    it "returns false if the queue is not empty" do
      queue.push("item1", "item2")

      expect(queue).not_to be_empty
    end
  end
end
