# frozen_string_literal: true

RSpec.describe Falqon::Queue do
  subject(:queue) { described_class.new("name") }

  describe "#name" do
    it "prepends a prefix" do
      expect(queue.name).to eq "falqon/name"
    end

    context "when no prefix is configured" do
      it "does not prepend a prefix" do
        allow(Falqon.configuration)
          .to receive(:prefix)
          .and_return(nil)

        expect(queue.name).to eq "name"
      end
    end
  end


  describe "#push" do
    it "pushes a single message to the queue and returns the identifier" do
      id = queue.push("message1")

      expect(id).to eq 1

      redis.with do |r|
        # Check that the identifiers have been pushed to the queue
        expect(r.lrange("falqon/name", 0, -1)).to eq ["1"]

        # Check that the messages have been stored
        expect(r.get("falqon/name:messages:1")).to eq "message1"

        # Check that the processing queue is empty
        expect(r.llen("falqon/name:processing")).to eq 0

        # Check that the identifier counter is incremented
        expect(r.get("falqon/name:id")).to eq "1"
      end
    end

    it "pushes messages to the queue and returns the identifiers" do
      id1, id2 = queue.push("message1", "message2")

      expect(id1).to eq 1
      expect(id2).to eq 2

      redis.with do |r|
        # Check that the identifiers have been pushed to the queue
        expect(r.lrange("falqon/name", 0, -1)).to eq ["1", "2"]

        # Check that the messages have been stored
        expect(r.get("falqon/name:messages:1")).to eq "message1"
        expect(r.get("falqon/name:messages:2")).to eq "message2"

        # Check that the processing queue is empty
        expect(r.llen("falqon/name:processing")).to eq 0

        # Check that the identifier counter is incremented
        expect(r.get("falqon/name:id")).to eq "2"
      end
    end
  end

  describe "#pop" do
    it "pops a message from the queue and returns it" do
      queue.push("message1", "message2")

      expect(queue.pop).to eq "message1"
      expect(queue.pop).to eq "message2"
    end

    context "when the queue is empty" do
      it "blocks until a message is pushed to the queue" do
        expect { queue.pop }.to raise_error MockRedis::WouldBlock
      end
    end

    context "when a block is given" do
      it "pops a message from the queue and yields it" do
        queue.push("message1", "message2")

        expect { |b| queue.pop(&b) }.to yield_with_args("message1")
        expect { |b| queue.pop(&b) }.to yield_with_args("message2")
      end

      it "requeues messages if they fail" do
        queue.push("message1", "message2")

        queue.pop { raise Falqon::Error }

        redis.with do |r|
          # Check that the identifiers have been pushed to the queue
          expect(r.lrange("falqon/name", 0, -1)).to eq ["2", "1"]
        end
      end

      it "discards messages if they fail too many times" do
        queue.push("message1")

        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }

        expect { |b| queue.pop(&b) }.to raise_error MockRedis::WouldBlock

        redis.with do |r|
          expect(r.lrange("falqon/name", 0, -1)).to be_empty
          expect(r.lrange("falqon/name:dead", 0, -1)).to eq ["1"]

          expect(r.get("falqon/name:retries:1")).to be_nil
        end
      end

      context "when the queue is empty" do
        it "blocks until a message is pushed to the queue" do
          expect { |b| queue.pop(&b) }.to raise_error MockRedis::WouldBlock
        end
      end
    end
  end

  describe "#peek" do
    it "peeks at the next message from the queue and returns it" do
      queue.push("message1", "message2")

      expect(queue.peek).to eq "message1"
      expect(queue.peek).to eq "message1"
    end

    context "when the queue is empty" do
      it "returns nil" do
        expect(queue.peek).to be_nil
      end
    end
  end

  describe "#clear" do
    it "clears the queue" do
      queue.push("message1", "message2")

      queue.clear

      expect(queue).to be_empty

      redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys).to be_empty
      end
    end

    it "returns the deleted messages' identifiers" do
      queue.push("message1", "message2")

      expect(queue.clear).to eq [1, 2]
    end
  end

  describe "#size" do
    it "returns the size of the queue" do
      queue.push("message1", "message2")

      expect(queue.size).to eq 2
    end
  end

  describe "#empty?" do
    it "returns true if the queue is empty" do
      expect(queue).to be_empty
    end

    it "returns false if the queue is not empty" do
      queue.push("message1", "message2")

      expect(queue).not_to be_empty
    end
  end

  def redis
    Falqon.redis
  end
end
