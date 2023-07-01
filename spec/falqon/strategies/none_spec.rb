# frozen_string_literal: true

RSpec.describe Falqon::Strategies::None do
  subject(:queue) { Falqon::Queue.new("name", retry_strategy: :none) }

  describe "#retry" do
    it "removes the identifier from the processing queue" do
      queue.push("message1")

      queue.pop { raise Falqon::Error }

      queue.redis.with do |r|
        expect(r.lrange(queue.name, 0, -1)).to be_empty
        expect(r.lrange(queue.processing.name, 0, -1)).to be_empty
        expect(r.lrange(queue.dead.name, 0, -1)).to eq ["1"]
      end
    end
  end
end
