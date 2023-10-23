# frozen_string_literal: true

module Falqon
  class CLI
    class Show < Base
      def call
        return puts "No queue registered with this name: #{options[:queue]}" unless Falqon::Queue.all.map(&:id).include?(options[:queue])

        queue = Falqon::Queue.new(options[:queue])

        queue.redis.with do |r|
          r.lrange(queue.name, 0, -1).each do |id|
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
