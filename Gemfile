# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in falqon.gemspec
gemspec

# Task runner
gem "rake", "13.2.1", require: false

group :development do
  # Documentation
  gem "yard", "0.9.37", require: false
  gem "yard-sorbet", "0.9.0", require: false

  # Simple server
  gem "webrick", "1.9.0", require: false
end

group :development, :test do
  # Debugger
  gem "debug", "1.9.2", require: false

  # Build objects for tests
  gem "factory_bot", "6.5.0", require: false

  # Generate fake data
  gem "ffaker", "2.23.0", require: false

  # Mock Redis server
  gem "mock_redis", "0.45.0", require: false

  # Behavior-driven test framework
  gem "rspec", "3.13.0", require: false

  # Linter
  gem "rubocop", "1.68.0", require: false
  gem "rubocop-factory_bot", "2.26.1", require: false
  gem "rubocop-performance", "1.22.1", require: false
  gem "rubocop-rake", "0.6.0", require: false
  gem "rubocop-rspec", "3.2.0", require: false

  # Type checker
  gem "sorbet", "0.5.11645", require: false
  gem "tapioca", "0.16.4", require: false

  # Time control
  gem "timecop", "0.9.10", require: false
end
