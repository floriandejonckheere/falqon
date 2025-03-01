# frozen_string_literal: true

require "json"

RSpec.configure do |config|
  def print_queue(queue)
    queue.redis.with do |r|
      puts queue.id
      puts "  pending: [#{r.lrange(queue.id, 0, -1).map { |id| r.get("#{queue.id}:data:#{id}") }.join(', ')}]"
      puts "  processing: [#{r.lrange(queue.processing.id, 0, -1).map { |id| r.get("#{queue.id}:data:#{id}") }.join(', ')}]"
      puts "  scheduled: [#{r.zrange(queue.scheduled.id, 0, -1).map { |id| r.get("#{queue.id}:data:#{id}") }.join(', ')}]"
      puts "  dead: [#{r.lrange(queue.dead.id, 0, -1).map { |id| r.get("#{queue.id}:data:#{id}") }.join(', ')}]"
    end
  end

  config.before do
    # Configure fake Redis connection pool
    Falqon.configure do |c|
      c.redis = ConnectionPool.new(size: 1) { MockRedis.new }
    end

    # Remove all queues
    Falqon::Queue.all.each(&:delete)

    # Set up a test set

    # queue0
    #   pending: [message6, message7, message3]
    #   processing: [message5]
    #   scheduled: [message4]
    #   dead: []
    # queue1
    #   pending: []
    #   processing: []
    #   scheduled: []
    #   dead: [message8, message9]
    # queue2
    #   pending: []
    #   processing: []
    #   scheduled: []
    #   dead: []
    # metadata
    #   3 queues
    #   9 processed
    #   2 retried

    queue0 = Falqon::Queue.new("queue0", retry_strategy: :linear, retry_delay: 60, max_retries: 3)

    Timecop.travel(1) { queue0.push(JSON.generate({ id: "message1" })) }
    Timecop.travel(2) { queue0.push(JSON.generate({ id: "message2" })) }
    Timecop.travel(3) { queue0.push(JSON.generate({ id: "message3" })) }
    Timecop.travel(4) { queue0.push(JSON.generate({ id: "message4" })) }
    Timecop.travel(5) { queue0.push(JSON.generate({ id: "message5" })) }
    Timecop.travel(6) { queue0.push(JSON.generate({ id: "message6" })) }
    Timecop.travel(7) { queue0.push(JSON.generate({ id: "message7" })) }

    queue0.pop # message1 removed
    queue0.pop # message2 removed
    queue0.pop { raise Falqon::Error } # message3 moved to scheduled
    Timecop.travel(2) { queue0.pop { raise Falqon::Error } } # message4 moved to scheduled

    # Reschedule message3 to pending
    Timecop.travel(queue0.retry_delay) { queue0.schedule }

    begin
      queue0.pop { raise StandardError }
    rescue StandardError
      # Do nothing, so message5 stays in the processing queue
    end

    queue1 = Timecop.travel(1) do
      queue1 = Falqon::Queue.new("queue1", retry_strategy: :linear, retry_delay: 60, max_retries: 2)

      queue1.push(JSON.generate({ id: "message8" }))
      queue1.push(JSON.generate({ id: "message9" }))

      queue1.pop { raise Falqon::Error } # message7 moved to scheduled
      queue1.pop { raise Falqon::Error } # message8 moved to scheduled

      # Reschedule message7 and message8 to pending
      Timecop.travel(queue1.retry_delay + 1) { queue1.schedule }

      queue1.pop { raise Falqon::Error }
      queue1.pop { raise Falqon::Error }

      queue1
    end

    queue2 = Timecop.travel(2) do
      Falqon::Queue.new("queue2")
    end

    # Comment out the next line to print the test set after initialization
    next if true # rubocop:disable Lint/LiteralAsCondition

    print_queue(queue0)
    print_queue(queue1)
    print_queue(queue2)

    puts "metadata"
    queues = Falqon::Queue.all
    puts "  #{queues.count} queues"
    puts "  #{queues.sum { |q| q.metadata.processed }} processed"
    puts "  #{queues.sum { |q| q.metadata.retried }} retried"
  end
end
