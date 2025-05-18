# frozen_string_literal: true

RSpec.describe Falqon::Commands::Version do
  subject(:command) { described_class.new(options) }

  let(:options) { {} }

  describe "#execute" do
    it "prints the version" do
      expect { command.call }
        .to output("Falqon #{Falqon::VERSION}\n")
        .to_stdout
    end
  end
end
