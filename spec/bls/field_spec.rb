require 'spec_helper'

RSpec.describe BLS::Field do

  describe "#==" do
    it do
      a = BLS::Fr.new(3)
      expect(a).to eq(BLS::Fr.new(3))
      expect(a).not_to eq(BLS::Fr.new(4))
      expect(a).not_to eq(BLS::Fp.new(3))
    end
  end

  describe '#invert' do
    # The extended Euclid used here falls out with 0 for a zero input, which is a wrong
    # answer rather than a failure, and it spreads: to_affine inverts z, so the point at
    # infinity used to come back as the affine coordinates (0, 0).
    it 'refuses zero' do
      [BLS::Fp::ZERO, BLS::Fr::ZERO, BLS::Fp2::ZERO, BLS::Fp6::ZERO, BLS::Fp12::ZERO].each do |zero|
        expect { zero.invert }.to raise_error(BLS::Error, 'Zero has no multiplicative inverse.')
      end
      expect { BLS::Fp.new(5) / BLS::Fp::ZERO }.to raise_error(BLS::Error)
      expect { BLS::Fp2.new([5, 5]) / BLS::Fp2::ZERO }.to raise_error(BLS::Error)
      expect { BLS::PointG1::ZERO.to_affine }.to raise_error(BLS::Error)
      expect { BLS::PointG2::ZERO.to_affine }.to raise_error(BLS::Error)
    end

    it 'inverts everything else' do
      expect(BLS::Fr.new(12345) * BLS::Fr.new(12345).invert).to eq(BLS::Fr::ONE)
      10.times { |i| a = BLS::Fp.new(i + 1); expect(a * a.invert).to eq(BLS::Fp::ONE) }
      a = BLS::Fp2.new([3, 7])
      expect(a * a.invert).to eq(BLS::Fp2::ONE)
      a = BLS::Fp6.from_tuple([1, 2, 3, 4, 5, 6])
      expect(a * a.invert).to eq(BLS::Fp6::ONE)
      a = BLS::Fp12.from_tuple((1..12).to_a)
      expect(a * a.invert).to eq(BLS::Fp12::ONE)
    end
  end

  describe '#sgn0' do
    # RFC 9380 section 4.1: s = sign_0 OR (zero_0 AND sign_1).
    def reference(x0, x1)
      x0.odd? || (x0.zero? && x1.odd?) ? 1 : 0
    end

    # x_1 was never consulted before, because sign_0 is 0 or 1 and 0 is truthy in Ruby, so
    # `sign_0 || ...` short circuited on it every time.
    it 'consults x_1 when x_0 is zero' do
      expect(BLS.sgn0(BLS::Fp2.new([0, 1]))).to eq(1)
      expect(BLS.sgn0(BLS::Fp2.new([0, 3]))).to eq(1)
      expect(BLS.sgn0(BLS::Fp2.new([0, 2]))).to eq(0)
      expect(BLS.sgn0(BLS::Fp2.new([0, 0]))).to eq(0)
    end

    it 'agrees with the specification' do
      order = BLS::Fp::ORDER
      edges = [[0, 0], [0, 1], [0, 2], [1, 0], [2, 0], [1, 1], [2, 1], [order - 1, 0], [0, order - 1]]
      (edges + 200.times.map { [rand(order), rand(order)] }).each do |x0, x1|
        expect(BLS.sgn0(BLS::Fp2.new([x0, x1]))).to eq(reference(x0, x1))
      end
    end
  end
end