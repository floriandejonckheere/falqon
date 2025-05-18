# frozen_string_literal: true

RSpec.describe Falqon::Commands::List do
  subject(:command) { described_class.new }

  describe "#execute" do
    it "displays all queues" do
      expect { command.call }
        .to output("queue0\nqueue1\nqueue2\n")
        .to_stdout
    end
  end
end
