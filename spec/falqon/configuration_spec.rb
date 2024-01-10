# frozen_string_literal: true

RSpec.describe Falqon::Configuration do
  subject(:configuration) { described_class.new }

  describe "#prefix" do
    it "has a default value" do
      expect(configuration.prefix).to eq "falqon"
    end

    it "can be set" do
      configuration.prefix = "foo"
      expect(configuration.prefix).to eq "foo"
    end
  end

  describe "#retry_strategy" do
    it "has a default value" do
      expect(configuration.retry_strategy).to eq :linear
    end

    it "can be set" do
      configuration.retry_strategy = :none
      expect(configuration.retry_strategy).to eq :none
    end

    it "rejects invalid values" do
      expect { configuration.retry_strategy = :foo }.to raise_error ArgumentError
    end
  end

  describe "#max_retries" do
    it "has a default value" do
      expect(configuration.max_retries).to eq 3
    end

    it "can be set" do
      configuration.max_retries = 10
      expect(configuration.max_retries).to eq 10
    end
  end

  describe "#retry_delay" do
    it "has a default value" do
      expect(configuration.retry_delay).to eq 0
    end

    it "can be set" do
      configuration.retry_delay = 10
      expect(configuration.retry_delay).to eq 10
    end
  end
end
