# frozen_string_literal: true

RSpec.describe Falqon::Entry do
  subject(:entry) { described_class.new(queue, message: "message") }

  let(:queue) { Falqon::Queue.new("name") }

  describe "#id" do
    it "returns an identifier" do
      entry = described_class.new(queue, id: 2)

      expect(entry.id).to eq 2
    end

    it "increments the identifier counter" do
      entry.id

      queue.redis.with do |r|
        expect(r.get("falqon/name:id")).to eq "1"
      end
    end
  end

  describe "#message" do
    it "returns a message" do
      entry = described_class.new(queue, message: "message1")

      expect(entry.message).to eq "message1"
    end

    it "retrieves the message" do
      described_class
        .new(queue, id: 2, message: "message1")
        .create

      entry = described_class.new(queue, id: 2)

      expect(entry.message).to eq "message1"
    end
  end

  describe "#create" do
    it "stores the message" do
      described_class
        .new(queue, id: 2, message: "message1")
        .create

      queue.redis.with do |r|
        expect(r.get("falqon/name:messages:2")).to eq "message1"
      end
    end

    it "sets the metadata" do
      Timecop.freeze do
        time = Time.now.to_i

        entry = described_class
          .new(queue, id: 2, message: "message1")
          .create

        expect(entry.metadata.status).to eq "unknown"
        expect(entry.metadata.retries).to eq 0
        expect(entry.metadata.created_at).to eq time
        expect(entry.metadata.updated_at).to eq time
      end
    end
  end

  describe "#kill" do
    it "moves the message to the dead queue" do
      entry = described_class
        .new(queue, id: 2, message: "message1")
        .create

      entry
        .kill

      expect(queue.pending).to be_empty
      expect(queue.processing).to be_empty
      expect(queue.dead).not_to be_empty
    end

    it "resets the retry count and sets the status to 'dead'" do
      entry = described_class
        .new(queue, id: 2, message: "message1")
        .create

      entry
        .kill

      expect(entry.metadata.retries).to be_zero
      expect(entry.metadata.status).to eq "dead"
    end
  end

  describe "#delete" do
    it "removes the message from the queues" do
      entry = described_class
        .new(queue, id: 2, message: "message1")
        .create

      entry
        .delete

      expect(queue.pending).to be_empty
      expect(queue.processing).to be_empty
      expect(queue.dead).to be_empty
    end

    it "deletes the message and metadata" do
      entry = described_class
        .new(queue, id: 2, message: "message1")
        .create

      entry
        .delete

      queue.redis.with do |r|
        expect(r.get("falqon/name:messages:2")).to be_nil
        expect(r.get("falqon/name:metadata:2")).to be_nil
      end
    end
  end

  describe "#metadata" do
    it "returns metadata" do
      Timecop.freeze do
        time = Time.now.to_i

        id = queue.push("message2")

        entry = described_class.new(queue, id:)

        metadata = entry.metadata

        expect(metadata.status).to eq "pending"
        expect(metadata.retries).to eq 0
        expect(metadata.created_at).to eq time
        expect(metadata.updated_at).to eq time
      end
    end
  end
end
