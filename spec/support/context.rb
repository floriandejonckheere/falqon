# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    # Configure fake Redis connection pool
    Falqon.configure do |c|
      c.redis = ConnectionPool.new(size: 1) { MockRedis.new }
    end

    # Remove all queues
    Falqon::Queue.all.each(&:delete)

    # Set up a test set

    # queue0
    #   pending: [message4, message5, message6, message2]
    #   processing: [message3]
    #   scheduled: []
    #   dead: []
    # queue1
    #   pending: []
    #   processing: []
    #   scheduled: []
    #   dead: [message7, message8]
    # queue2
    #   pending: []
    #   processing: []
    #   scheduled: []
    #   dead: []
    # metadata
    #   3 queues
    #   8 processed
    #   4 scheduled
    #   2 retried

    queue0 = Falqon::Queue.new("queue0")

    Timecop.travel(1) { queue0.push("message0") }
    Timecop.travel(2) { queue0.push("message1") }
    Timecop.travel(3) { queue0.push("message2") }
    Timecop.travel(4) { queue0.push("message3") }
    Timecop.travel(5) { queue0.push("message4") }
    Timecop.travel(6) { queue0.push("message5") }
    Timecop.travel(7) { queue0.push("message6") }

    queue0.pop
    queue0.pop
    queue0.pop { raise Falqon::Error }

    begin
      queue0.pop { raise StandardError }
    rescue StandardError
      # Do nothing, so the message stays in the processing queue
    end

    queue1 = Timecop.travel(1) do
      queue1 = Falqon::Queue.new("queue1")

      Timecop.travel(1) { queue1.push("message7") }
      Timecop.travel(2) { queue1.push("message8") }

      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }

      queue1
    end

    queue2 = Timecop.travel(2) do
      Falqon::Queue.new("queue2")
    end

    # Comment out the next line to print the test set after initialization
    next if true # rubocop:disable Lint/LiteralAsCondition

    Falqon.redis.with do |r|
      puts "queue0"
      puts "  pending: [#{r.lrange(queue0.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"
      puts "  processing: [#{r.lrange(queue0.processing.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"
      puts "  scheduled: [#{r.lrange(queue0.scheduled.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"
      puts "  dead: [#{r.lrange(queue0.dead.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"

      puts "queue1"
      puts "  pending: [#{r.lrange(queue1.id, 0, -1).map { |id| r.get("#{queue1.id}:data:#{id}") }.join(', ')}]"
      puts "  processing: [#{r.lrange(queue1.processing.id, 0, -1).map { |id| r.get("#{queue1.id}:data:#{id}") }.join(', ')}]"
      puts "  scheduled: [#{r.lrange(queue0.scheduled.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"
      puts "  dead: [#{r.lrange(queue1.dead.id, 0, -1).map { |id| r.get("#{queue1.id}:data:#{id}") }.join(', ')}]"

      puts "queue2"
      puts "  pending: [#{r.lrange(queue2.id, 0, -1).map { |id| r.get("#{queue2.id}:data:#{id}") }.join(', ')}]"
      puts "  processing: [#{r.lrange(queue2.processing.id, 0, -1).map { |id| r.get("#{queue2.id}:data:#{id}") }.join(', ')}]"
      puts "  scheduled: [#{r.lrange(queue0.scheduled.id, 0, -1).map { |id| r.get("#{queue0.id}:data:#{id}") }.join(', ')}]"
      puts "  dead: [#{r.lrange(queue2.dead.id, 0, -1).map { |id| r.get("#{queue2.id}:data:#{id}") }.join(', ')}]"

      puts "metadata"
      queues = Falqon::Queue.all
      puts "  #{queues.count} queues"
      puts "  #{queues.sum { |q| q.metadata.processed }} processed"
      puts "  #{queues.sum { |q| q.metadata.scheduled }} scheduled"
      puts "  #{queues.sum { |q| q.metadata.retried }} retried"
    end
  end
end
