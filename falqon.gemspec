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
  spec.license       = "LGPL-3.0-or-later"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.2")

  spec.metadata["source_code_uri"] = "https://github.com/floriandejonckheere/falqon.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["README.md", "LICENSE.md", "CHANGELOG.md", "Gemfile", "bin/falqon", "lib/**/*.rb", "config/*.rb"]
  spec.bindir        = "bin"
  spec.executables   = ["falqon"]
  spec.require_paths = ["lib"]

  spec.add_dependency "connection_pool", "~> 2.5"
  spec.add_dependency "redis", "~> 5.4"
  spec.add_dependency "sorbet-runtime", "~> 0.5"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.7"
end
