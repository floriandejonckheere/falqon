# frozen_string_literal: true

# typed: true

module Falqon
  module Touch
    extend T::Sig

    sig { params(names: Symbol).void }
    def touch(*names)
      redis.with do |r|
        names.each do |n|
          # Set timestamp
          r.hset("#{name}:stats", n, Time.now.to_i)
        end
      end
    end
  end
end
