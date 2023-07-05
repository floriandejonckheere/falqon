# frozen_string_literal: true

RSpec.describe Falqon::Strategies::Linear do
  subject(:queue) { Falqon::Queue.new("name", retry_strategy: :linear) }

  describe "#retry" do
    it "requeues messages if they fail" do
      queue.push("message1", "message2")

      queue.pop { raise Falqon::Error }

      queue.redis.with do |r|
        expect(r.lrange("falqon/name", 0, -1)).to eq ["2", "1"]

        expect(r.hget("falqon/name:stats:1", :retries)).to eq "1"
      end
    end

    it "discards messages if they fail too many times" do
      queue.push("message1")

      queue.pop { raise Falqon::Error }
      queue.pop { raise Falqon::Error }
      queue.pop { raise Falqon::Error }

      queue.redis.with do |r|
        expect(r.lrange("falqon/name", 0, -1)).to be_empty
        expect(r.lrange("falqon/name:processing", 0, -1)).to be_empty
        expect(r.lrange("falqon/name:dead", 0, -1)).to eq ["1"]

        expect(r.hget("falqon/name:stats:1", :retries)).to be_nil
      end
    end
  end
end
