# frozen_string_literal: true

RSpec.describe Falqon::CLI do
  subject(:cli) { described_class.new }

  it { is_expected.to respond_to :version }
  it { is_expected.to respond_to :status }
  it { is_expected.to respond_to :show }
  it { is_expected.to respond_to :clear }
end
