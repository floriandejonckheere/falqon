# frozen_string_literal: true

RSpec.shared_examples "touch" do
  describe "#touch" do
    it "updates the timestamp" do
      Timecop.freeze do
        time = Time.now.to_i

        subject.touch(:created_at, :updated_at)

        expect(subject.stats.created_at).to eq time
        expect(subject.stats.updated_at).to eq time

        Timecop.travel(60)

        subject.touch(:updated_at)

        expect(subject.stats.created_at).to eq time
        expect(subject.stats.updated_at).to eq(time + 60)
      end
    end
  end
end
