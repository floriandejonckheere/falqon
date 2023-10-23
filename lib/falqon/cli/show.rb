# frozen_string_literal: true

module Falqon
  class CLI
    class Show < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])
      end

      def execute
        queue = Falqon::Queue.new(options[:queue])

        subqueue = if options[:processing]
                     queue.processing
                   elsif options[:dead]
                     queue.dead
                   else
                     queue.pending
                   end

        queue.redis.with do |r|
          r.lrange(subqueue.name, 0, -1).each do |id|
            entry = Falqon::Entry.new(queue, id: id.to_i)

            next puts entry.message if options[:data]

            puts "id = #{entry.id} " \
                 "retries = #{entry.metadata.retries} " \
                 "created_at = #{Time.at(entry.metadata.created_at)} " \
                 "updated_at = #{Time.at(entry.metadata.updated_at)} " \
                 "message = #{entry.message.length} bytes"
          end
        end
      end
    end
  end
end
