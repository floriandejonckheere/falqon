# frozen_string_literal: true

require_relative "lib/falqon/version"

Gem::Specification.new do |spec|
  spec.name          = "falqon"
  spec.version       = Falqon::VERSION
  spec.authors       = ["Florian Dejonckheere"]
  spec.email         = ["florian@floriandejonckheere.be"]

  spec.summary       = "Simple messaging queue"
  spec.description   = "Simple, efficient, and reliable messaging queue for Ruby"
  spec.homepage      = "https://github.com/floriandejonckheere/falqon"
  spec.license       = "LGPL-3.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")

  spec.metadata["source_code_uri"] = "https://github.com/floriandejonckheere/falqon.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["README.md", "LICENSE.md", "CHANGELOG.md", "Gemfile", "bin/falqon", "lib/**/*.rb", "config/*.rb"]
  spec.bindir        = "bin"
  spec.executables   = ["falqon"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "connection_pool", "~> 2.4"
  spec.add_runtime_dependency "redis", "~> 5.0"
  spec.add_runtime_dependency "sorbet-runtime", "~> 0.5"
  spec.add_runtime_dependency "thor", "~> 1.3"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"
end
