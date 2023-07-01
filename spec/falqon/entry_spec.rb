# frozen_string_literal: true

RSpec.describe Falqon::Entry do
  subject(:entry) { described_class.new(queue) }

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
  end

  describe "#delete" do
    it "deletes the message" do
      described_class
        .new(queue, id: 2, message: "message1")
        .create
        .delete

      queue.redis.with do |r|
        expect(r.get("falqon/name:messages:2")).to be_nil
        expect(r.get("falqon/name:retries:2")).to be_nil
      end
    end
  end
end
