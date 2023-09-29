# frozen_string_literal: true

RSpec.describe Falqon::Version do
  it "has a version number" do
    expect(Falqon::VERSION).not_to be_nil
  end
end
