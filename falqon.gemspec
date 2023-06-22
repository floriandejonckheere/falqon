# frozen_string_literal: true

require_relative "lib/falqon/version"

Gem::Specification.new do |spec|
  spec.name          = "falqon"
  spec.version       = Falqon::VERSION
  spec.authors       = ["Florian Dejonckheere"]
  spec.email         = ["florian@floriandejonckheere.be"]

  spec.summary       = "Simple messaging queue"
  spec.description   = "Simple, efficient messaging queue for Ruby"
  spec.homepage      = "https://github.com/floriandejonckheere/falqon"
  spec.license       = "LGPL-3.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0")

  spec.metadata["source_code_uri"] = "https://github.com/floriandejonckheere/falqon.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["README.md", "LICENSE.md", "CHANGELOG.md", "Gemfile", "lib/falqon/**/*.rb", "config/*.rb"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "zeitwerk"
end
