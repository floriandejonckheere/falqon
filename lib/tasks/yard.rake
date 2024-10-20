# frozen_string_literal: true

require "yard"
require "yard-sorbet"

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.options = ["--title", "Falqon", "--plugin", "yard-sorbet"]
end
