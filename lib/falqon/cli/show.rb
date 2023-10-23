# frozen_string_literal: true

module Falqon
  class CLI
    class Show < Base
      def validate
        raise "No queue registered with this name: #{options[:queue]}" if options[:queue] && !Falqon::Queue.all.map(&:id).include?(options[:queue])

        raise "--pending, --processing, and --dead are mutually exclusive" if [options[:pending], options[:processing], options[:dead]].count(true) > 1
        raise "--meta and --data are mutually exclusive" if [options[:meta], options[:data]].count(true) > 1
      end

      def execute
        queue.redis.with do |r|
          r.lrange(subqueue.name, 0, -1).each do |id|
            entry = Falqon::Entry.new(queue, id: id.to_i)

            next puts entry.message if options[:data]

            if options[:meta]
              puts "id = #{entry.id} " \
                   "retries = #{entry.metadata.retries} " \
                   "created_at = #{Time.at(entry.metadata.created_at)} " \
                   "updated_at = #{Time.at(entry.metadata.updated_at)} " \
                   "message = #{entry.message.length} bytes"
            else
              puts "id = #{entry.id} message = #{entry.message.length} bytes"
            end
          end
        end
      end

      private

      def queue
        @queue ||= Falqon::Queue.new(options[:queue])
      end

      def subqueue
        @subqueue ||= if options[:processing]
                        queue.processing
                      elsif options[:dead]
                        queue.dead
                      else
                        queue.pending
                      end
      end
    end
  end
end
