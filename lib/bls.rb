# frozen_string_literal: true

require 'digest'
require 'bls/version'
require 'bls/math'
require 'bls/curve'
require 'bls/field'
require 'bls/point'
require 'bls/pairing'

module BLS

  class Error < StandardError; end

  POW_2_381 = 2**381
  POW_2_382 = POW_2_381 * 2
  POW_2_383 = POW_2_382 * 2

  PUBLIC_KEY_LENGTH = 48
  SHA256_DIGEST_SIZE = 32

  DST_LABEL = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_'

  module_function

  # Generate BLS signature: s = pk x H(m)
  # @param [String] message Message digest(hash value with hex format) to be signed.
  # @param [Integer|String] private_key The private key used for signing. Integer or String(hex).
  # @return [PointG2] The signature point.
  def sign(message, private_key)
    msg_point = BLS.norm_p2h(message)
    msg_point * BLS.normalize_priv_key(private_key)
  end
end
