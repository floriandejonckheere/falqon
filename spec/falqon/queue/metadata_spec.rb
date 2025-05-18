# frozen_string_literal: true

RSpec.describe Falqon::Queue::Metadata do
  subject(:metadata) { described_class.new }

  describe "#initialize" do
    it "returns a new instance with default values" do
      expect(metadata.processed).to be_zero
      expect(metadata.failed).to be_zero
      expect(metadata.retried).to be_zero
    end
  end
end
