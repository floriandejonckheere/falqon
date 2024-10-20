# frozen_string_literal: true

# typed: true

module Falqon
  extend T::Sig

  # Base class for queue identifiers
  #
  Identifier = T.type_alias { Integer }
end
