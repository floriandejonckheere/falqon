# frozen_string_literal: true

FactoryBot.define do
  factory :queue, class: Falqon::Queue do
    sequence(:name) { |n| "queue#{n}" }
    retry_strategy { :linear }
    max_retries { 3 }
    retry_delay { 60 }

    initialize_with { new(name, retry_strategy:, max_retries:, retry_delay:) }
  end
end
