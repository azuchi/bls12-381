# frozen_string_literal: true

require 'bls/version'
require 'bls/math'
require 'bls/curve'
require 'bls/field'
require 'bls/point'

module BLS

  class Error < StandardError; end

  POW_2_381 = 2**381
  POW_2_382 = POW_2_381 * 2
  POW_2_383 = POW_2_382 * 2

  PUBLIC_KEY_LENGTH = 48
  SHA256_DIGEST_SIZE = 32

end
