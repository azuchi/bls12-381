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
  # @param [String] message Message digest(hex format) to be signed.
  # @param [Integer|String] private_key The private key used for signing. Integer or String(hex).
  # @param [Symbol] sig_type Signature type, :g1 or :g2.
  # If :g1 is specified, the signature is a point on G1 and the public key is a point on G2.
  # If :g2 is specified, the signature is a point on G2 and the public key is a point on G1.
  # @return [PointG2] The signature point.
  def sign(message, private_key, sig_type: :g2)
    msg_point = case sig_type
                when :g1
                  BLS.norm_p1h(message)
                when :g2
                  BLS.norm_p2h(message)
                else
                  raise Error, 'sig_type must be :g1 or :g2.'
                end
    msg_point * BLS.normalize_priv_key(private_key)
  end

  # Generate public key from +private_key+.
  # @param [Integer|String] private_key The private key. Integer or String(hex).
  # @param [Symbol] key_type Public key type, :g1 or :g2.
  # @return [BLS::PointG1|BLS::PointG2] public key.
  def get_public_key(private_key, key_type: :g1)
    case key_type
    when :g1
      PointG1.from_private_key(private_key)
    when :g2
      PointG2.from_private_key(private_key)
    else
      raise Error, 'key_type must be :g1 or :g2.'
    end
  end

  # Verify BLS signature. Verify one of the following:
  # * Public key is a point on G1, signature is a point on G2 or
  # * Public key is a point on G2, signature is a point on G1.
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
    exp == Fp12::ONE
  end

  # Aggregate multiple public keys.
  # @param [Array[BLS::PointG1]|Array[BLS::PointG2]] public_keys the list of public keys.
  # @return [BLS::PointG1|BLS::PointG2] aggregated public key.
  def aggregate_public_keys(public_keys)
    raise BLS::Error, 'Expected non-empty array.' if public_keys.empty?
    g1_flag = public_keys.first.is_a?(PointG1)
    sum = g1_flag ? PointG1::ZERO : PointG2::ZERO
    public_keys.each do |pubkey|
      if g1_flag && !pubkey.is_a?(PointG1) || !g1_flag && !pubkey.is_a?(PointG2)
        raise BLS::Error, 'Point G1 and G2 are mixed.'
      end
      sum += pubkey
    end
    sum
  end

  # Aggregate multiple signatures.
  # e(G, S) = e(G, sum(n)Si) = mul(n)(e(G, Si))
  # @param [Array[BLS::PointG2]|Array[BLS::PointG2]] signatures multiple signatures.
  # @return [BLS::PointG2|BLS::PointG1] aggregated signature.
  def aggregate_signatures(signatures)
    raise BLS::Error, 'Expected non-empty array.' if signatures.empty?

    g2_flag = signatures.first.is_a?(PointG2)
    sum = g2_flag ? PointG2::ZERO : PointG1::ZERO
    signatures.each do |signature|
      if g2_flag && !signature.is_a?(PointG2) || !g2_flag && !signature.is_a?(PointG1)
        raise BLS::Error, 'Signature G1 and G2 are mixed.'
      end
      sum += signature
    end
    sum
  end

  # Verify aggregated signature.
  # @param [BLS::PointG2|BLS::PointG1] signature aggregated signature(BLS::PointG2 or BLS::PointG1).
  # @param [Array[String]] messages the list of message.
  # @param [Array[BLS::PointG1]|Array[BLS::PointG2]] public_keys the list of public keys(BLS::PointG1 or BLS::PointG2).
  # @return [Boolean] verification result.
  def verify_batch(signature, messages, public_keys)
    raise BLS::Error, 'Expected non-empty array.' if messages.empty?
    raise BLS::Error, 'Public keys count should equal msg count.' unless messages.size == public_keys.size

    sig_g2_flag = signature.is_a?(PointG2)
    public_keys.each do |public_key|
      if sig_g2_flag && !public_key.is_a?(PointG1) || !sig_g2_flag && !public_key.is_a?(PointG2)
        raise BLS::Error, "Public key must be #{sig_g2_flag ? 'PointG1' : 'PointG2'}"
      end
    end

    n_message = messages.map { |m| sig_g2_flag ? BLS.norm_p2h(m) : BLS.norm_p1h(m)}
    paired = []
    zero = sig_g2_flag ? PointG1::ZERO : PointG2::ZERO
    n_message.each do |message|
      group_pubkey = n_message.each_with_index.inject(zero)do|group_pubkey, (sub_message, i)|
        sub_message == message ? group_pubkey + public_keys[i] : group_pubkey
      end
      paired << (sig_g2_flag ? BLS.pairing(group_pubkey, message, with_final_exp: false) :
                   BLS.pairing(message, group_pubkey, with_final_exp: false))
    end
    paired << (sig_g2_flag ? BLS.pairing(PointG1::BASE.negate, signature, with_final_exp: false) :
                 BLS.pairing(signature, PointG2::BASE.negate, with_final_exp: false))
    product = paired.inject(Fp12::ONE) { |a, b| a * b }
    product.final_exponentiate == Fp12::ONE
  end
end
