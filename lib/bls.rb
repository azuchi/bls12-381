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

  # Generate public key from +private_key+.
  # @param [Integer|String] private_key The private key. Integer or String(hex).
  # @return [BLS::PointG1] public key.
  def get_public_key(private_key)
    PointG1.from_private_key(private_key)
  end

  # Verify BLS signature.
  # @param [String] signature
  # @param [String] message Message digest(hash value with hex format) to be verified.
  # @param [String] public_key Public key with hex format.
  # @return [Boolean] verification result.
  def verify(signature, message, public_key)
    p = BLS.norm_p1(public_key)
    hm = BLS.norm_p2h(message)
    g = PointG1::BASE
    s = BLS.norm_p2(signature)
    ephm = BLS.pairing(p.negate, hm, with_final_exp: false)
    egs = BLS.pairing(g, s, with_final_exp: false)
    exp = (egs * ephm).final_exponentiate
    exp == Fq12::ONE
  end
end
