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
  # @param [Symbol] scheme Signature scheme, :basic or :pop. Signatures made under one scheme
  # do not verify under the other, so signer and verifier must agree on it.
  # @return [PointG2] The signature point.
  def sign(message, private_key, sig_type: :g2, scheme: :basic)
    msg_point = case sig_type
                when :g1
                  BLS.norm_p1h(message, scheme: scheme)
                when :g2
                  BLS.norm_p2h(message, scheme: scheme)
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
  # @param [Symbol] scheme Signature scheme the signature was made under, :basic or :pop.
  # @return [Boolean] verification result.
  def verify(signature, message, public_key, scheme: :basic)
    unless signature.is_a?(PointG1) && public_key.is_a?(PointG2) ||
      signature.is_a?(PointG2) && public_key.is_a?(PointG1)
      raise BLS::Error, 'Invalid signature or public key. If the public key is PointG1, the signature must be an element of Point::G2 or vice versa.'
    end
    # KeyValidate of draft-irtf-cfrg-bls-signature section 2.5. The identity is not a public
    # key anybody holds, and pairing it away would leave the identity signature verifying
    # against every message.
    return false if public_key.zero?

    g = public_key.is_a?(PointG1) ? PointG1::BASE : PointG2::BASE
    ephm = if public_key.is_a?(PointG1)
             hm = BLS.norm_p2h(message, scheme: scheme)
             BLS.partial_pairing(public_key.negate, hm)
           else
             hm = BLS.norm_p1h(message, scheme: scheme)
             BLS.partial_pairing(hm, public_key.negate)
           end
    egs = if public_key.is_a?(PointG1)
            BLS.partial_pairing(g, signature)
          else
            BLS.partial_pairing(signature, g)
          end
    exp = (egs * ephm).final_exponentiate
    exp == Fp12::ONE
  end

  # Aggregate multiple public keys.
  #
  # WARNING: the aggregate is only meaningful once every input key has been checked with
  # {pop_verify}. Without that check an attacker who publishes pk_a = g * x - pk_victim
  # can produce, on their own, a signature that verifies against the aggregate, making it
  # look like the victim signed. See {fast_aggregate_verify}.
  #
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
  #
  # Under the :basic scheme the messages must all be distinct: repeating one is reported as
  # an invalid signature, since that scheme has nothing but message distinctness to stop a
  # rogue key from signing on another key's behalf. Use :pop, whose proofs of possession rule
  # that out, to verify several signatures over the same message.
  #
  # @param [BLS::PointG2|BLS::PointG1] signature aggregated signature(BLS::PointG2 or BLS::PointG1).
  # @param [Array[String]] messages the list of message.
  # @param [Array[BLS::PointG1]|Array[BLS::PointG2]] public_keys the list of public keys(BLS::PointG1 or BLS::PointG2).
  # @param [Symbol] scheme Signature scheme the signatures were made under, :basic or :pop.
  # @return [Boolean] verification result.
  def verify_batch(signature, messages, public_keys, scheme: :basic)
    raise BLS::Error, 'Expected non-empty array.' if messages.empty?
    raise BLS::Error, 'Public keys count should equal msg count.' unless messages.size == public_keys.size

    sig_g2_flag = signature.is_a?(PointG2)
    public_keys.each do |public_key|
      if sig_g2_flag && !public_key.is_a?(PointG1) || !sig_g2_flag && !public_key.is_a?(PointG2)
        raise BLS::Error, "Public key must be #{sig_g2_flag ? 'PointG1' : 'PointG2'}"
      end
    end
    return false if public_keys.any?(&:zero?) # KeyValidate, as in #verify

    n_message = messages.map { |m| sig_g2_flag ? BLS.norm_p2h(m, scheme: scheme) : BLS.norm_p1h(m, scheme: scheme)}

    # Keys that signed the same message are summed so that message is paired exactly once:
    # e(P1, Q) * e(P2, Q) == e(P1 + P2, Q). Grouping on the serialized point rather than on
    # the message keeps this independent of how equal messages happened to be spelled.
    zero = sig_g2_flag ? PointG1::ZERO : PointG2::ZERO
    grouped = {}
    n_message.each_with_index do |message, i|
      group = (grouped[message.to_hex(compressed: true)] ||= [message, zero])
      group[1] += public_keys[i]
    end
    return false if scheme == :basic && grouped.size < n_message.size

    paired = grouped.each_value.map do |message, group_pubkey|
      sig_g2_flag ? BLS.partial_pairing(group_pubkey, message) :
        BLS.partial_pairing(message, group_pubkey)
    end
    paired << (sig_g2_flag ? BLS.partial_pairing(PointG1::BASE.negate, signature) :
                 BLS.partial_pairing(signature, PointG2::BASE.negate))
    product = paired.inject(Fp12::ONE) { |a, b| a * b }
    product.final_exponentiate == Fp12::ONE
  end

  # Generate a proof of possession for +private_key+: a signature, under that key, over the
  # public key it belongs to. Producing one requires knowing the private key, which is what
  # makes aggregation safe against rogue key attacks.
  # @param [Integer|String] private_key The private key. Integer or String(hex).
  # @param [Symbol] key_type Public key type, :g1 or :g2. The proof lives in the other group.
  # @return [BLS::PointG2|BLS::PointG1] proof of possession.
  def pop_prove(private_key, key_type: :g1)
    public_key = get_public_key(private_key, key_type: key_type)
    msg = public_key.to_hex(compressed: true)
    msg_point = public_key.is_a?(PointG1) ? BLS.norm_p2h(msg, scheme: :pop_proof) :
                  BLS.norm_p1h(msg, scheme: :pop_proof)
    msg_point * BLS.normalize_priv_key(private_key)
  end

  # Verify a proof of possession produced by {pop_prove}.
  # @param [BLS::PointG1|BLS::PointG2] public_key the public key being proven.
  # @param [BLS::PointG2|BLS::PointG1] proof proof of possession.
  # @return [Boolean] verification result.
  def pop_verify(public_key, proof)
    verify(proof, public_key.to_hex(compressed: true), public_key, scheme: :pop_proof)
  end

  # Verify an aggregated signature over a single message signed by every key in +public_keys+.
  #
  # WARNING: every public key must have passed {pop_verify} first. This check cannot be done
  # here because it needs each key's proof, and skipping it reopens the rogue key attack that
  # the pop scheme exists to prevent.
  #
  # @param [BLS::PointG2|BLS::PointG1] signature aggregated signature.
  # @param [String] message Message digest(hash value with hex format) to be verified.
  # @param [Array[BLS::PointG1]|Array[BLS::PointG2]] public_keys the list of public keys.
  # @return [Boolean] verification result.
  def fast_aggregate_verify(signature, message, public_keys)
    verify(signature, message, aggregate_public_keys(public_keys), scheme: :pop)
  end
end
