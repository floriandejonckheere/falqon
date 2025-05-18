# frozen_string_literal: true

RSpec.describe Falqon::Message::Metadata do
  subject(:metadata) { described_class.new }

  describe "#initialize" do
    it "returns a new instance with default values" do
      expect(metadata.status).to eq "unknown"
      expect(metadata.retries).to be_zero
    end
  end
end
