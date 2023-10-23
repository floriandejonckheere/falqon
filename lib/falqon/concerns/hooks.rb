# frozen_string_literal: true

# typed: true

module Falqon
  module Hooks
    extend T::Sig

    sig { params(base: T.class_of(Hooks)).void }
    def self.included(base)
      base.extend(ClassMethods)
    end

    sig { params(event: Symbol, type: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
    def run_hook(event, type = nil, &block)
      T.unsafe(self).class.hooks[event][:before].each { |hook| instance_eval(&hook) } if type.nil? || type == :before

      block&.call

      T.unsafe(self).class.hooks[event][:after].each { |hook| instance_eval(&hook) } if type.nil? || type == :after
    end

    module ClassMethods
      include Kernel
      extend T::Sig

      sig { returns(T::Hash[Symbol, T::Hash[Symbol, T::Array[T.proc.void]]]) }
      def hooks
        @hooks ||= Hash.new { |h, k| h[k] = { before: [], after: [] } }
      end

      # Add hook to before list (either the given block or a wrapped method call)
      sig { params(event: Symbol, method_sym: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
      def before(event, method_sym = nil, &block)
        block ||= proc { send(method_sym) } if method_sym

        T.must(T.must(hooks[event])[:before]) << block if block
      end

      # Add hook to after list (either the given block or a wrapped method call)
      sig { params(event: Symbol, method_sym: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
      def after(event, method_sym = nil, &block)
        block ||= proc { send(method_sym) } if method_sym

        T.must(T.must(hooks[event])[:after]) << block if block
      end
    end
  end
end
