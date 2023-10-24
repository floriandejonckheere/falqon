# frozen_string_literal: true

RSpec.describe Falqon::CLI::Queues do
  subject(:command) { described_class.new }

  before do
    # Register queues
    Falqon::Queue.new("foo")
    Falqon::Queue.new("bar")
  end

  describe "#execute" do
    it "displays all queues" do
      expect { command.call }
        .to output("bar\nfoo\n")
        .to_stdout
    end
  end
end
