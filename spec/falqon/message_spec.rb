# frozen_string_literal: true

RSpec.describe Falqon::Message do
  subject(:message) { described_class.new(queue, data: "message") }

  let(:queue) { Falqon::Queue.new("name") }

  describe "#id" do
    it "returns an identifier" do
      message = described_class.new(queue, id: 2)

      expect(message.id).to eq 2
    end

    it "increments the identifier counter" do
      message.id

      queue.redis.with do |r|
        expect(r.get("falqon/name:id")).to eq "1"
      end
    end
  end

  describe "#data" do
    it "returns a message" do
      message = described_class.new(queue, data: "message1")

      expect(message.data).to eq "message1"
    end

    it "retrieves the message" do
      described_class
        .new(queue, id: 2, data: "message1")
        .create

      message = described_class.new(queue, id: 2)

      expect(message.data).to eq "message1"
    end
  end

  describe "#unknown?" do
    it "returns true if the status is unknown" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      expect(message).to be_unknown
    end
  end

  describe "#pending?" do
    it "returns true if the status is pending" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      # FIXME: mock the status correctly
      message.queue.redis.with do |r|
        r.hset("#{message.queue.id}:metadata:#{message.id}", "status", "pending")
      end

      expect(message).to be_pending
    end
  end

  describe "#processing?" do
    it "returns true if the status is processing" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      # FIXME: mock the status correctly
      message.queue.redis.with do |r|
        r.hset("#{message.queue.id}:metadata:#{message.id}", "status", "processing")
      end

      expect(message).to be_processing
    end
  end

  describe "#dead?" do
    it "returns true if the status is dead" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      message
        .kill

      expect(message).to be_dead
    end
  end

  describe "#exists?" do
    it "returns true if the message exists" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      expect(message).to exist
    end

    it "returns false if the message does not exist" do
      message = described_class
        .new(queue, id: 2, data: "message1")

      expect(message).not_to exist
    end
  end

  describe "#create" do
    it "stores the message" do
      described_class
        .new(queue, id: 2, data: "message1")
        .create

      queue.redis.with do |r|
        expect(r.get("falqon/name:data:2")).to eq "message1"
      end
    end

    it "sets the metadata" do
      Timecop.freeze do
        time = Time.now.to_i

        message = described_class
          .new(queue, id: 2, data: "message1")
          .create

        expect(message.metadata.status).to eq "unknown"
        expect(message.metadata.retries).to eq 0
        expect(message.metadata.created_at).to eq time
        expect(message.metadata.updated_at).to eq time
      end
    end
  end

  describe "#kill" do
    it "moves the message to the dead queue" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      message
        .kill

      expect(queue.pending).to be_empty
      expect(queue.processing).to be_empty
      expect(queue.dead).not_to be_empty
    end

    it "resets the retry count and sets the status to 'dead'" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      message
        .kill

      expect(message.metadata.retries).to be_zero
      expect(message.metadata.status).to eq "dead"
    end
  end

  describe "#delete" do
    it "removes the message from the queues" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      message
        .delete

      expect(queue.pending).to be_empty
      expect(queue.processing).to be_empty
      expect(queue.dead).to be_empty
    end

    it "deletes the message and metadata" do
      message = described_class
        .new(queue, id: 2, data: "message1")
        .create

      message
        .delete

      queue.redis.with do |r|
        expect(r.get("falqon/name:data:2")).to be_nil
        expect(r.get("falqon/name:metadata:2")).to be_nil
      end
    end
  end

  describe "#metadata" do
    it "returns metadata" do
      Timecop.freeze do
        time = Time.now.to_i

        id = queue.push("message2")

        message = described_class.new(queue, id:)

        metadata = message.metadata

        expect(metadata.status).to eq "pending"
        expect(metadata.retries).to eq 0
        expect(metadata.created_at).to eq time
        expect(metadata.updated_at).to eq time
      end
    end
  end
end
