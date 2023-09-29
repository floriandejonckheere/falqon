# frozen_string_literal: true

# typed: true

module Falqon
  module Touch
    extend T::Sig

    sig { params(names: Symbol).void }
    def touch(*names)
      time = Time.now.to_i

      key = [name, "stats", (id if respond_to?(:id))].compact.join(":")

      redis.with do |r|
        names.each do |n|
          # Set timestamp
          r.hset(key, n, time)
        end
      end
    end
  end
end
