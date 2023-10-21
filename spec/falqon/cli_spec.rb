# frozen_string_literal: true

RSpec.describe Falqon::CLI do
  subject(:cli) { described_class.new }

  describe "#version" do
    it "prints the version" do
      expect { cli.version }
        .to output("Falqon #{Falqon::VERSION}\n")
        .to_stdout
    end
  end
end
