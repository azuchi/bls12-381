# frozen_string_literal: true

require 'spec_helper'

# Test vectors from ethereum/bls12-381-tests. See spec/fixtures/bls12-381-tests/README.md for
# where they come from and which ciphersuite each handler uses.
RSpec.describe 'ethereum/bls12-381-tests' do

  # The tag RFC 9380 uses for its own hash to curve vectors, which is not a signature suite.
  RFC9380_G2_DST = 'QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_'

  def vectors(handler)
    paths = Dir[File.join(File.dirname(__FILE__), '..', 'fixtures', 'bls12-381-tests', handler, '*.json')]
    expect(paths).not_to be_empty
    paths.sort.map { |path| [File.basename(path, '.json'), JSON.parse(File.read(path))] }
  end

  def unprefixed(hex)
    hex.delete_prefix('0x')
  end

  def pubkey(hex)
    BLS::PointG1.from_hex(unprefixed(hex))
  end

  def signature(hex)
    BLS::PointG2.from_hex(unprefixed(hex))
  end

  # A point that will not deserialize is an invalid input, not an exception for the caller of
  # a verification function to deal with.
  def verifying
    yield
  rescue BLS::PointError
    false
  end

  # Pinned so that a botched update to the fixtures shows up as a failure rather than as a
  # handler quietly covering fewer cases than it used to.
  it 'has every vector of the release it was taken from' do
    counts = {
      'aggregate' => 6, 'aggregate_verify' => 5, 'batch_verify' => 4,
      'deserialization_G1' => 13, 'deserialization_G2' => 15, 'fast_aggregate_verify' => 12,
      'hash_to_G2' => 4, 'sign' => 10, 'verify' => 29
    }
    counts.each { |handler, count| expect(vectors(handler).size).to eq(count), handler }
  end

  describe 'deserialization_G1' do
    it 'accepts exactly the encodings it should' do
      vectors('deserialization_G1').each do |name, vector|
        deserialized = begin
          pubkey(vector['input']['pubkey'])
          true
        rescue BLS::PointError
          false
        end
        expect(deserialized).to eq(vector['output']), name
      end
    end
  end

  describe 'deserialization_G2' do
    it 'accepts exactly the encodings it should' do
      vectors('deserialization_G2').each do |name, vector|
        deserialized = begin
          signature(vector['input']['signature'])
          true
        rescue BLS::PointError
          false
        end
        expect(deserialized).to eq(vector['output']), name
      end
    end
  end

  describe 'hash_to_G2' do
    it 'maps messages to the expected points' do
      vectors('hash_to_G2').each do |name, vector|
        # Unlike the other handlers, msg is a byte string rather than hex.
        point = BLS::PointG2.hash_to_curve(vector['input']['msg'].unpack1('H*'), dst: RFC9380_G2_DST)
        x, y = point.to_affine
        coordinates = lambda do |fp2|
          fp2.values.map { |c| "0x#{BLS.num_to_hex(c, BLS::PUBLIC_KEY_LENGTH)}" }.join(',')
        end
        expect({ 'x' => coordinates.call(x), 'y' => coordinates.call(y) }).to eq(vector['output']), name
      end
    end
  end

  describe 'sign' do
    it 'produces the expected signatures' do
      vectors('sign').each do |name, vector|
        input = vector['input']
        signing = -> { BLS.sign(unprefixed(input['message']), unprefixed(input['privkey']), scheme: :pop) }
        if vector['output'].nil?
          expect { signing.call }.to raise_error(BLS::Error), name
        else
          expect("0x#{signing.call.to_hex(compressed: true)}").to eq(vector['output']), name
        end
      end
    end
  end

  describe 'aggregate' do
    it 'sums signatures' do
      vectors('aggregate').each do |name, vector|
        aggregating = -> { BLS.aggregate_signatures(vector['input'].map { |hex| signature(hex) }) }
        if vector['output'].nil?
          expect { aggregating.call }.to raise_error(BLS::Error), name
        else
          expect("0x#{aggregating.call.to_hex(compressed: true)}").to eq(vector['output']), name
        end
      end
    end
  end

  describe 'verify' do
    it 'agrees on every case' do
      vectors('verify').each do |name, vector|
        input = vector['input']
        result = verifying do
          BLS.verify(signature(input['signature']), unprefixed(input['message']),
                     pubkey(input['pubkey']), scheme: :pop)
        end
        expect(result).to eq(vector['output']), name
      end
    end
  end

  describe 'aggregate_verify' do
    it 'agrees on every case' do
      vectors('aggregate_verify').each do |name, vector|
        input = vector['input']
        result = verifying do
          BLS.verify_batch(signature(input['signature']),
                           input['messages'].map { |m| unprefixed(m) },
                           input['pubkeys'].map { |k| pubkey(k) }, scheme: :pop)
        end
        expect(result).to eq(vector['output']), name
      end
    end
  end

  describe 'fast_aggregate_verify' do
    it 'agrees on every case' do
      vectors('fast_aggregate_verify').each do |name, vector|
        input = vector['input']
        result = verifying do
          BLS.fast_aggregate_verify(signature(input['signature']), unprefixed(input['message']),
                                    input['pubkeys'].map { |k| pubkey(k) })
        end
        expect(result).to eq(vector['output']), name
      end
    end
  end

  describe 'batch_verify' do
    # This library has no dedicated call for a set of independent signatures, so each triple
    # is verified on its own and the set stands or falls together.
    it 'agrees on every case' do
      vectors('batch_verify').each do |name, vector|
        input = vector['input']
        result = verifying do
          input['pubkeys'].zip(input['messages'], input['signatures']).all? do |key, message, sig|
            BLS.verify(signature(sig), unprefixed(message), pubkey(key), scheme: :pop)
          end
        end
        expect(result).to eq(vector['output']), name
      end
    end
  end
end
