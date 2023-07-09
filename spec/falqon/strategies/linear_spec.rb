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

    context "when processing fails too many times" do
      it "kills messages" do
        queue.push("message1")

        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }

        expect(queue.pending).to be_empty
        expect(queue.processing).to be_empty
        expect(queue.dead).not_to be_empty
      end

      it "resets the retry counter" do
        id = queue.push("message1")

        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }
        queue.pop { raise Falqon::Error }

        entry = Falqon::Entry.new(queue, id:)

        expect(entry.stats[:retries]).to be_zero
      end
    end
  end
end
