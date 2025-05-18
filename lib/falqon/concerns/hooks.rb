# frozen_string_literal: true

# typed: true

module Falqon
  # Hooks can be registered on a custom queue to execute code before and after certain events.
  # The following hooks are available:
  # - +after :initialize+: executed after the queue has been initialized
  # - +before :push+: executed before a message is pushed to the queue
  # - +after :push+: executed after a message has been pushed to the queue
  # - +before :pop+: executed before a message is popped from the queue
  # - +after :pop+: executed after a message has been popped from the queue (but before deleting it)
  # - +before :peek+: executed before peeking to a message in the queue
  # - +after :peek+: executed after peeking to a message in the queue
  # - +before :range+: executed before peeking to a message range in the queue
  # - +after :range+: executed after peeking to a message range in the queue
  # - +before :clear+: executed before clearing the queue
  # - +after :clear+: executed after clearing the queue
  # - +before :delete+: executed before deleting the queue
  # - +after :delete+: executed after deleting the queue
  # - +before :refill+: executed before refilling the queue
  # - +after :refill+: executed after refilling the queue
  # - +before :revive+: executed before reviving a message from the dead queue
  # - +after :revive+: executed after reviving a message from the dead queue
  # - +before :schedule+: executed before scheduling messages for retry
  # - +after :schedule+: executed after scheduling messages for retry
  #
  # @example
  #  class MyQueue < Falqon::Queue
  #   before :push, :my_custom_method
  #
  #    after :delete do
  #     ...
  #    end
  #
  #    private
  #
  #    def my_custom_method
  #      ...
  #    end
  #  end
  #
  module Hooks
    extend T::Sig

    # @!visibility private
    sig { params(base: Class).void }
    def self.included(base)
      base.extend(ClassMethods)
    end

    # @!visibility private
    sig { params(event: Symbol, type: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
    def run_hook(event, type = nil, &block)
      T.unsafe(self).class.hooks[event][:before].each { |hook| instance_eval(&hook) } if type.nil? || type == :before

      block&.call

      T.unsafe(self).class.hooks[event][:after].each { |hook| instance_eval(&hook) } if type.nil? || type == :after
    end

    module ClassMethods
      include Kernel
      extend T::Sig

      # @!visibility private
      sig { returns(T::Hash[Symbol, T::Hash[Symbol, T::Array[T.proc.void]]]) }
      def hooks
        @hooks ||= Hash.new { |h, k| h[k] = { before: [], after: [] } }
      end

      # Add hook to before list (either the given block or a wrapped method call)
      #
      # @param event The event to hook into
      # @param method_sym The method to call
      # @param block The block to execute
      # @return [void]
      #
      sig { params(event: Symbol, method_sym: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
      def before(event, method_sym = nil, &block)
        block ||= proc { send(method_sym) } if method_sym

        T.must(T.must(hooks[event])[:before]) << block if block
      end

      # Add hook to after list (either the given block or a wrapped method call)
      #
      # @param event The event to hook into
      # @param method_sym The method to call
      # @param block The block to execute
      # @return [void]
      #
      sig { params(event: Symbol, method_sym: T.nilable(Symbol), block: T.nilable(T.proc.void)).void }
      def after(event, method_sym = nil, &block)
        block ||= proc { send(method_sym) } if method_sym

        T.must(T.must(hooks[event])[:after]) << block if block
      end
    end
  end
end
