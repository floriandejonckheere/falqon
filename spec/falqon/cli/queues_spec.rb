# frozen_string_literal: true

RSpec.describe Falqon::CLI::Queues do
  subject(:command) { described_class.new }

  include_context "with a couple of queues"

  describe "#execute" do
    it "displays all queues" do
      expect { command.call }
        .to output("bar\nfoo\n")
        .to_stdout
    end
  end
end
