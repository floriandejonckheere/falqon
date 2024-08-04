# frozen_string_literal: true

RSpec.describe Falqon::Queue do
  subject(:queue) { described_class.new("name") }

  before { Falqon.redis.with(&:flushdb) }

  describe "#initialize" do
    it "registers the queue" do
      queue

      expect(described_class.all.map(&:name)).to include "name"
    end

    it "sets the creation and update timestamps exactly once" do
      Timecop.freeze do
        time = Time.now.to_i

        queue = described_class.new("name")

        expect(queue.metadata.created_at).to be_within(1).of time
        expect(queue.metadata.updated_at).to be_within(1).of time

        Timecop.travel(60)

        queue = described_class.new("name")

        expect(queue.metadata.created_at).to be_within(1).of time
        expect(queue.metadata.updated_at).to be_within(1).of time
      end
    end

    it "sets the protocol version" do
      queue

      expect(queue.metadata.version).to eq Falqon::PROTOCOL
    end

    it "raises when the protocol version does not match" do
      described_class.new("name")

      stub_const("Falqon::PROTOCOL", -1)

      expect { queue }.to raise_error(Falqon::VersionMismatchError)
    end
  end

  describe "#id" do
    it "prepends a prefix" do
      expect(queue.id).to eq "falqon/name"
    end

    context "when no prefix is configured" do
      it "does not prepend a prefix" do
        allow(Falqon.configuration)
          .to receive(:prefix)
          .and_return(nil)

        expect(queue.id).to eq "name"
      end
    end
  end

  describe "#push" do
    it "pushes a single message to the queue and returns the identifier" do
      id = queue.push("message1")

      expect(id).to eq 1

      queue.redis.with do |r|
        # Check that the identifiers have been pushed to the queue
        expect(r.lrange("falqon/name", 0, -1)).to eq ["1"]

        # Check that the messages have been stored
        expect(r.get("falqon/name:data:1")).to eq "message1"

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

      queue.redis.with do |r|
        # Check that the identifiers have been pushed to the queue
        expect(r.lrange("falqon/name", 0, -1)).to eq ["1", "2"]

        # Check that the messages have been stored
        expect(r.get("falqon/name:data:1")).to eq "message1"
        expect(r.get("falqon/name:data:2")).to eq "message2"

        # Check that the processing queue is empty
        expect(r.llen("falqon/name:processing")).to eq 0

        # Check that the identifier counter is incremented
        expect(r.get("falqon/name:id")).to eq "2"
      end
    end

    it "sets the update timestamp" do
      Timecop.freeze do
        time = Time.now.to_i

        queue

        expect(queue.metadata.updated_at).to be_within(1).of time

        Timecop.travel(60)

        queue.push("message1")

        expect(queue.metadata.updated_at).to be_within(1).of(time + 60)
      end
    end

    it "sets the message status to pending" do
      id = queue.push("message1")

      message = Falqon::Message.new(queue, id:)

      expect(message.metadata.status).to eq "pending"
    end
  end

  describe "#pop" do
    it "pops a message from the queue and returns it" do
      queue.push("message1", "message2")

      expect(queue.pop).to eq "message1"
      expect(queue.pop).to eq "message2"
    end

    it "sets the update timestamp" do
      Timecop.freeze do
        time = Time.now.to_i

        queue.push("message1")

        expect(queue.metadata.updated_at).to be_within(1).of time

        Timecop.travel(60)

        queue.pop

        expect(queue.metadata.updated_at).to be_within(1).of(time + 60)
      end
    end

    it "sets the message status to processing" do
      id = queue.push("message1")

      message = Falqon::Message.new(queue, id:)

      queue.pop do
        expect(message.metadata.status).to eq "processing"
      end
    end

    it "increments the processing counter" do
      queue.push("message1")

      expect { queue.pop }.to change { queue.metadata.processed }.from(0).to 1
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

      it "increments the processing counter" do
        queue.push("message1")

        expect { queue.pop { nil } }.to change { queue.metadata.processed }.from(0).to 1
      end

      it "increments the retry counter if the message is retried" do
        queue.push("message1")

        queue.pop { raise Falqon::Error }

        expect { queue.pop { nil } }.to change { queue.metadata.retried }.from(0).to 1
      end

      it "increments the failure counter if the message raised an error" do
        queue.push("message1")

        expect { queue.pop { raise Falqon::Error } }.to change { queue.metadata.failed }.from(0).to 1
      end

      context "when the queue is empty" do
        it "blocks until a message is pushed to the queue" do
          expect { |b| queue.pop(&b) }.to raise_error MockRedis::WouldBlock
        end
      end
    end
  end

  describe "#peek" do
    it "returns the first message in the queue" do
      queue.push("message1", "message2")

      expect(queue.peek).to eq "message1"
      expect(queue.peek).to eq "message1"
    end

    it "returns the nth message in the queue" do
      queue.push("message1", "message2", "message3")

      expect(queue.peek(index: 0)).to eq "message1"
      expect(queue.peek(index: 1)).to eq "message2"
      expect(queue.peek(index: 2)).to eq "message3"
    end

    context "when the queue is empty" do
      it "returns nil" do
        expect(queue.peek).to be_nil
      end
    end
  end

  describe "#range" do
    it "returns the messages in the queue" do
      queue.push("message1", "message2", "message3")

      expect(queue.range).to eq ["message1", "message2", "message3"]
    end

    it "returns the identifiers in the queue in the given range" do
      queue.push("message1", "message2", "message3")

      expect(queue.range(start: 1)).to eq ["message2", "message3"]
      expect(queue.range(start: 1, stop: 1)).to eq ["message2"]
      expect(queue.range(start: 1, stop: 2)).to eq ["message2", "message3"]
      expect(queue.range(stop: 1)).to eq ["message1", "message2"]
    end

    context "when the queue is empty" do
      it "returns an empty array" do
        expect(queue.range).to be_empty
      end
    end
  end

  describe "#clear" do
    it "clears the queue" do
      queue.push("message1", "message2")

      queue.clear

      expect(queue).to be_empty

      expect(queue.metadata.processed).to eq 0
      expect(queue.metadata.failed).to eq 0
      expect(queue.metadata.retried).to eq 0

      queue.redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys - ["falqon:queues", "falqon/name:metadata"]).to be_empty
      end
    end

    it "sets the update timestamp" do
      Timecop.freeze do
        time = Time.now.to_i

        queue.push("message1")

        expect(queue.metadata.updated_at).to be_within(1).of time

        Timecop.travel(60)

        queue.clear

        expect(queue.metadata.updated_at).to be_within(1).of(time + 60)
      end
    end

    it "returns the deleted messages' identifiers" do
      queue.push("message1", "message2")

      expect(queue.clear).to eq [1, 2]
    end

    context "when the queue is empty" do
      it "returns an empty array" do
        expect(queue.clear).to be_empty
      end
    end
  end

  describe "#delete" do
    it "deletes the queue" do
      queue.push("message1", "message2")

      queue.delete

      expect(queue).to be_empty

      queue.redis.with do |r|
        # Check that all keys have been deleted
        expect(r.keys - ["falqon:queues"]).to be_empty
      end
    end

    it "deregisters the queue" do
      queue.push("message1", "message2")

      queue.delete

      expect(described_class.all).to be_empty
    end
  end

  describe "#refill" do
    it "refills the queue" do
      queue.push("message1", "message2", "message3", "message4")

      queue.pop do
        queue.pop do
          queue.refill

          queue.redis.with do |r|
            # Check that the identifiers have been pushed back to the queue
            expect(r.lrange("falqon/name", 0, -1)).to eq ["1", "2", "3", "4"]

            # Check that the message status has been set to pending
            expect(r.hget("falqon/name:metadata:1", :status)).to eq "pending"
            expect(r.hget("falqon/name:metadata:2", :status)).to eq "pending"
            expect(r.hget("falqon/name:metadata:3", :status)).to eq "pending"
            expect(r.hget("falqon/name:metadata:4", :status)).to eq "pending"
          end
        end
      end
    end
  end

  describe "#revive" do
    it "revives the queue" do
      queue.push("message1", "message2", "message3", "message4")

      10.times { queue.pop { raise Falqon::Error } }

      queue.revive

      queue.redis.with do |r|
        # Check that the identifiers have been pushed back to the queue
        expect(r.lrange("falqon/name", 0, -1)).to eq ["1", "2", "3", "4"]

        # Check that the message status has been set to pending
        expect(r.hget("falqon/name:metadata:1", :status)).to eq "pending"
        expect(r.hget("falqon/name:metadata:2", :status)).to eq "pending"
        expect(r.hget("falqon/name:metadata:3", :status)).to eq "pending"
        expect(r.hget("falqon/name:metadata:4", :status)).to eq "pending"
      end
    end
  end

  describe "#schedule" do
    let(:queue) { described_class.new("name", retry_strategy: :linear, retry_delay: 60, max_retries: 3) }

    it "schedules due messages" do
      Timecop.freeze(1970, 1, 1, 1, 0, 0)

      queue.push("message1", "message2")

      # Raise an error to rechedule the message
      queue.pop { raise Falqon::Error }
      Timecop.travel(1) { queue.pop { raise Falqon::Error } }

      queue.schedule

      # Neither message1 nor message2 should have been scheduled
      expect(queue).to be_empty

      Timecop.travel(queue.retry_delay) do
        queue.schedule

        # message1 should have been scheduled, but message2 should not
        queue.redis.with do |r|
          expect(r.lrange("falqon/name", 0, -1)).to eq ["1"]
          expect(r.zrange("falqon/name:scheduled", 0, -1)).to eq ["2"]
        end
      end
    end
  end

  describe "#size" do
    it "returns the size of the queue" do
      queue.push("message1", "message2")

      expect(queue.size).to eq 2
    end

    context "when the queue is empty" do
      it "returns 0" do
        expect(queue.size).to eq 0
      end
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

  describe "#metadata" do
    it "returns metadata" do
      Timecop.freeze do
        time = Time.now.to_i

        queue.push("message1", "message2")

        queue.pop
        queue.pop { raise Falqon::Error }

        Timecop.travel(60)

        queue.pop

        expect(queue.metadata.processed).to eq 3
        expect(queue.metadata.failed).to eq 1
        expect(queue.metadata.retried).to eq 1
        expect(queue.metadata.created_at).to eq time
        expect(queue.metadata.updated_at).to eq(time + 60)
      end
    end
  end

  describe ".all" do
    it "returns all queues" do
      queue

      expect(described_class.all.map(&:name)).to eq ["name"]
    end
  end
end
