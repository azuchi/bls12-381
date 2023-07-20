# frozen_string_literal: true

require 'digest'
require 'bls/version'
require 'bls/math'
require 'bls/curve'
require 'bls/field'
require 'bls/h2c'
require 'bls/point'
require 'bls/pairing'

module BLS

  class Error < StandardError; end

  POW_2_381 = 2**381
  POW_2_382 = POW_2_381 * 2
  POW_2_383 = POW_2_382 * 2

  PUBLIC_KEY_LENGTH = 48
  SHA256_DIGEST_SIZE = 32

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
  # @param [BLS::PointG1|BLS::PointG2] signature
  # @param [String] message Message digest(hash value with hex format) to be verified.
  # @param [BLS::PointG2|BLS::PointG1] public_key Public key with hex format or PointG1.
  # @return [Boolean] verification result.
  def verify(signature, message, public_key)
    unless signature.is_a?(PointG1) && public_key.is_a?(PointG2) ||
      signature.is_a?(PointG2) && public_key.is_a?(PointG1)
      raise BLS::Error, 'Invalid signature or public key. If the public key is PointG1, the signature must be an element of Point::G2 or vice versa.'
    end
    g = public_key.is_a?(PointG1) ? PointG1::BASE : PointG2::BASE
    ephm = if public_key.is_a?(PointG1)
             hm = BLS.norm_p2h(message)
             BLS.pairing(public_key.negate, hm, with_final_exp: false)
           else
             hm = BLS.norm_p1h(message)
             BLS.pairing(hm, public_key.negate, with_final_exp: false)
           end
    egs = if public_key.is_a?(PointG1)
            BLS.pairing(g, signature, with_final_exp: false)
          else
            BLS.pairing(signature, g, with_final_exp: false)
          end
    exp = (egs * ephm).final_exponentiate
    exp == Fq12::ONE
  end

  # Aggregate multiple public keys.
  # @param [Array[String]] public_keys the list of public keys.
  # @return [BLS::PointG1] aggregated public key.
  def aggregate_public_keys(public_keys)
    raise BLS::Error, 'Expected non-empty array.' if public_keys.empty?

    public_keys.map { |p| BLS.norm_p1(p) }.inject(PointG1::ZERO) { |sum, p| sum + p }
  end

  # Aggregate multiple signatures.
  # e(G, S) = e(G, sum(n)Si) = mul(n)(e(G, Si))
  # @param [Array[String|BLS::PointG2]] signatures multiple signatures.
  # @return [BLS::PointG2] aggregated signature.
  def aggregate_signatures(signatures)
    raise BLS::Error, 'Expected non-empty array.' if signatures.empty?

    signatures.map { |s| BLS.norm_p2(s) }.inject(PointG2::ZERO) { |sum, s| sum + s }
  end

  # Verify aggregated signature.
  # @param [BLS::PointG2] signature aggregated signature.
  # @param [Array[String]] messages the list of message.
  # @param [Array[String|BLS::PointG1]] public_keys the list of public keys with hex or BLS::PointG1 format.
  # @return [Boolean] verification result.
  def verify_batch(signature, messages, public_keys)
    raise BLS::Error, 'Expected non-empty array.' if messages.empty?
    raise BLS::Error, 'Public keys count should equal msg count.' unless messages.size == public_keys.size

    n_message = messages.map { |m| BLS.norm_p2h(m) }
    n_public_keys = public_keys.map { |p| BLS.norm_p1(p) }
    paired = []
    n_message.each do |message|
      group_pubkey = n_message.each_with_index.inject(PointG1::ZERO)do|group_pubkey, (sub_message, i)|
        sub_message == message ? group_pubkey + n_public_keys[i] : group_pubkey
      end
      paired << BLS.pairing(group_pubkey, message, with_final_exp: false)
    end
    sig = BLS.norm_p2(signature)
    paired << BLS.pairing(PointG1::BASE.negate, sig, with_final_exp: false)
    product = paired.inject(Fq12::ONE) { |a, b| a * b }
    product.final_exponentiate == Fq12::ONE
  end
end
