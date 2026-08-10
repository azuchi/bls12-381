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