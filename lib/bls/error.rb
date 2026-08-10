# frozen_string_literal: true

module BLS

  # Base class for everything this library raises about the data it was given, so that
  # `rescue BLS::Error` catches all of it.
  #
  # A wrong type or arity is a mistake in the calling code rather than a fact about a key or a
  # point, and still raises ArgumentError, as it would anywhere else in Ruby.
  class Error < StandardError; end

  # A point that could not be parsed, is not on the curve, or is not in the prime-order
  # subgroup.
  class PointError < Error; end

  # A pairing that was asked for where it is not defined.
  class PairingError < Error; end
end
