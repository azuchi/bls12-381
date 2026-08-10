# frozen_string_literal: true

require 'spec_helper'

# Hash to curve vectors from RFC 9380. See spec/fixtures/rfc9380/README.md.
RSpec.describe 'RFC 9380 hash to curve' do

  def load_suite(name)
    path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'rfc9380', "#{name}.json")
    JSON.parse(File.read(path))
  end

  # An Fp element, "0x...".
  def fp(hex)
    hex.delete_prefix('0x').to_i(16)
  end

  # An Fp2 element, written as its two coefficients "0x<c0>,0x<c1>".
  def fp2(hex)
    hex.split(',').map { |coefficient| fp(coefficient) }
  end

  describe 'BLS12381G2_XMD:SHA-256_SSWU_RO_' do
    let(:suite) { load_suite('BLS12381G2_XMD_SHA-256_SSWU_RO_') }

    it 'has the five vectors of the suite' do
      expect(suite['vectors'].size).to eq(5)
      expect(suite['dst']).to eq('QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_')
    end

    # Every stage is checked separately so that a failure names the one that broke, rather
    # than only saying the final point came out wrong.
    it 'reaches the expected field elements' do
      suite['vectors'].each do |vector|
        u = BLS::H2C::G2.hash_to_field(vector['msg'].unpack1('H*'), suite['dst'])
        expect(u).to eq(vector['u'].map { |element| fp2(element) }), vector['msg']
      end
    end

    it 'maps those onto the expected points' do
      suite['vectors'].each do |vector|
        u = BLS::H2C::G2.hash_to_field(vector['msg'].unpack1('H*'), suite['dst'])
        %w[Q0 Q1].each_with_index do |key, i|
          mapped = BLS::PointG2.new(*BLS::H2C::G2.isogeny_map(*BLS::H2C::G2.map_to_curve_sswu(u[i])))
          x, y = mapped.to_affine
          expect([x.values, y.values]).to eq([fp2(vector[key]['x']), fp2(vector[key]['y'])]),
                                          "#{key} of #{vector['msg']}"
        end
      end
    end

    it 'clears the cofactor onto the expected point' do
      suite['vectors'].each do |vector|
        x, y = BLS::PointG2.hash_to_curve(vector['msg'].unpack1('H*'), dst: suite['dst']).to_affine
        expect([x.values, y.values]).to eq([fp2(vector['P']['x']), fp2(vector['P']['y'])]), vector['msg']
      end
    end
  end

  describe 'BLS12381G1_XMD:SHA-256_SSWU_RO_' do
    let(:suite) { load_suite('BLS12381G1_XMD_SHA-256_SSWU_RO_') }

    it 'has the five vectors of the suite' do
      expect(suite['vectors'].size).to eq(5)
      expect(suite['dst']).to eq('QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_')
    end

    # Only the result: hash_to_field and the map are the h2c gem's, not this one's.
    it 'hashes onto the expected points' do
      suite['vectors'].each do |vector|
        x, y = BLS::PointG1.hash_to_curve(vector['msg'].unpack1('H*'), dst: suite['dst']).to_affine
        expect([x.value, y.value]).to eq([fp(vector['P']['x']), fp(vector['P']['y'])]), vector['msg']
      end
    end
  end
end
