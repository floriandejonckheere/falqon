# frozen_string_literal: true

RSpec.describe Falqon::Hooks do
  subject(:instance) { my_class.new }

  let(:my_class) do
    Class.new do
      include Falqon::Hooks

      attr_reader :result

      # Usage with a block
      before :call do
        result << "before"
      end

      # Usage with a method
      after :call, :after_call

      def initialize
        @result = []
      end

      def call
        run_hook :call do
          result << "call"
        end
      end

      def after_call
        result << "after"
      end

      def self.name
        "MyClass"
      end
    end
  end

  it "runs the configured hooks in-order" do
    instance.call

    expect(instance.result).to eq ["before", "call", "after"]
  end
end
