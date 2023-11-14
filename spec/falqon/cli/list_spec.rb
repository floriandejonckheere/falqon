# frozen_string_literal: true

RSpec.describe Falqon::CLI::List do
  subject(:command) { described_class.new }

  describe "#execute" do
    it "displays all queues" do
      expect { command.call }
        .to output("queue2\nqueue1\nqueue0\n")
        .to_stdout
    end
  end
end
