# frozen_string_literal: true

RSpec.describe Falqon::Hooks do
  subject(:my_instance) { my_class.new }

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

      def after_call
        result << "after"
      end

      def self.name
        "MyClass"
      end
    end
  end

  describe "with a block" do
    it "runs the configured hooks in-order" do
      my_instance.instance_eval do
        run_hook :call do
          result << "call"
        end
      end

      expect(my_instance.result).to eq ["before", "call", "after"]
    end

    context "when a type is specified" do
      it "runs only the hooks of the specified type" do
        my_instance.instance_eval do
          run_hook :call, :before do
            result << "call"
          end
        end

        expect(my_instance.result).to eq ["before", "call"]
      end
    end
  end

  describe "without a block" do
    it "runs the configured hooks in-order" do
      my_instance.instance_eval do
        run_hook :call
      end

      expect(my_instance.result).to eq ["before", "after"]
    end

    context "when a type is specified" do
      it "runs only the hooks of the specified type" do
        my_instance.instance_eval do
          run_hook :call, :before
        end

        expect(my_instance.result).to eq ["before"]
      end
    end
  end
end
