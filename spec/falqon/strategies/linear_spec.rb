# frozen_string_literal: true

RSpec.describe Falqon::Strategies::Linear do
  subject(:queue) { Falqon::Queue.new("name", retry_strategy: :linear, retry_delay:) }

  describe "#retry" do
    context "when retry delay is zero" do
      let(:retry_delay) { 0 }

      it "requeues messages immediately" do
        queue.push("message1", "message2")

        queue.pop { raise Falqon::Error }

        queue.redis.with do |r|
          expect(r.lrange("falqon/name", 0, -1)).to eq ["2", "1"]

          expect(r.hget("falqon/name:metadata:1", :retries)).to eq "1"
        end
      end

      it "sets the message status to pending" do
        id = queue.push("message1")

        queue.pop { raise Falqon::Error }

        message = Falqon::Message.new(queue, id:)

        expect(message.metadata.status).to eq "pending"
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

          message = Falqon::Message.new(queue, id:)

          expect(message.metadata.retries).to be_zero
        end

        it "sets the message status to dead" do
          id = queue.push("message1")

          queue.pop { raise Falqon::Error }
          queue.pop { raise Falqon::Error }
          queue.pop { raise Falqon::Error }

          message = Falqon::Message.new(queue, id:)

          expect(message.metadata.status).to eq "dead"
        end
      end
    end

    context "when retry delay is greater than zero" do
      let(:retry_delay) { 5 }

      it "reschedules messages" do
        queue.push("message1", "message2")

        queue.pop { raise Falqon::Error }

        queue.redis.with do |r|
          expect(r.lrange("falqon/name", 0, -1)).to eq ["2"]
          expect(r.zrange("falqon/name:scheduled", 0, -1)).to eq ["1"]

          expect(r.hget("falqon/name:metadata:1", :retries)).to eq "1"
        end
      end

      it "sets the message status to scheduled" do
        id = queue.push("message1")

        queue.pop { raise Falqon::Error }

        message = Falqon::Message.new(queue, id:)

        expect(message.metadata.status).to eq "scheduled"
      end

      context "when processing fails too many times" do
        it "kills messages" do
          queue.push("message1")

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          expect(queue.pending).to be_empty
          expect(queue.processing).to be_empty
          expect(queue.dead).not_to be_empty
        end

        it "resets the retry counter" do
          id = queue.push("message1")

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          message = Falqon::Message.new(queue, id:)

          expect(message.metadata.retries).to be_zero
        end

        it "sets the message status to dead" do
          id = queue.push("message1")

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          Timecop.travel(queue.retry_delay) { queue.schedule }

          queue.pop { raise Falqon::Error }

          message = Falqon::Message.new(queue, id:)

          expect(message.metadata.status).to eq "dead"
        end
      end
    end
  end
end
