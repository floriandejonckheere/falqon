# frozen_string_literal: true

RSpec.describe Falqon::Strategies::Linear do
  subject(:queue) { Falqon::Queue.new("name", retry_strategy: :linear) }

  describe "#retry" do
    it "requeues messages if they fail" do
      queue.push("message1", "message2")

      queue.pop { raise Falqon::Error }

      queue.redis.with do |r|
        expect(r.lrange(queue.name, 0, -1)).to eq ["2", "1"]

        expect(r.get("#{queue.name}:retries:1")).to eq "1"
      end
    end

    it "discards messages if they fail too many times" do
      queue.push("message1")

      queue.pop { raise Falqon::Error }
      queue.pop { raise Falqon::Error }
      queue.pop { raise Falqon::Error }

      queue.redis.with do |r|
        expect(r.lrange(queue.name, 0, -1)).to be_empty
        expect(r.lrange(queue.processing.name, 0, -1)).to be_empty
        expect(r.lrange(queue.dead.name, 0, -1)).to eq ["1"]

        expect(r.get("#{queue.name}:retries:1")).to be_nil
      end
    end
  end
end
