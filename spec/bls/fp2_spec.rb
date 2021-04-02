# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Fp2' do

  describe 'Fp2 equality' do
    it 'should be equal.' do
      NUM_RUNS.times do
        num1 = rand(1..BLS::Fq::ORDER)
        num2 = rand(1..BLS::Fq::ORDER)
        a = BLS::Fq2.new([num1, num2])
        b = BLS::Fq2.new([num1, num2])
        expect(a).to eq(b)
        expect(b).to eq(a)
      end
    end
  end

  describe 'Fp2 non-equality' do
    it 'should be not equal.' do
      NUM_RUNS.times do
        num1 = [rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)]
        num2 = [rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)]
        a = BLS::Fq2.new([num1[0], num1[1]])
        b = BLS::Fq2.new([num2[0], num2[1]])
        expect(a == b).to eq(num1[0] == num2[0] && num1[1] == num2[1])
        expect(b == a).to eq(num1[0] == num2[0] && num1[1] == num2[1])
      end
    end
  end

  describe 'Fp2 square and multiplication equality' do
    it 'should pass square and multiplication equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a.square).to eq(a * a)
      end
    end
  end

  describe 'Fp2 multiplication and add equality' do
    it 'should pass multiplication and add equality.' do
      NUM_RUNS.times do
        a = BLS::Fq2.new([rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)])
        expect(a * 0).to eq(BLS::Fq2::ZERO)
        expect(a * BLS::Fq2::ZERO).to eq(BLS::Fq2::ZERO)
        expect(a * 1).to eq(a)
        expect(a * BLS::Fq2::ONE).to eq(a)
        expect(a * 2).to eq(a + a)
        expect(a * 3).to eq(a + a + a)
        expect(a * 4).to eq(a + a + a + a)
      end
    end
  end

  describe 'Fp2 multiplication commutativity' do
    it 'should pass multiplication commutativity.' do
      NUM_RUNS.times do
        a, b = create_fq2_items(2)
        expect(a * b).to eq(b * a)
      end
    end
  end

  describe 'Fp2 multiplication associativity' do
    it 'should pass multiplication associativity.' do
      NUM_RUNS.times do
        a, b, c = create_fq2_items(3)
        expect(a * (b * c)).to eq(a * b * c)
      end
    end
  end

  describe 'Fp2 multiplication distributivity' do
    it 'should pass multiplication associativity.' do
      NUM_RUNS.times do
        a, b, c = create_fq2_items(3)
        expect(a * (b + c)).to eq(b * a + c * a)
      end
    end
  end

  describe 'Fp2 division with one equality' do
    it 'should pass division with one equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a / BLS::Fq2.new([1, 0])).to eq(a)
        expect(a / BLS::Fq2::ONE).to eq(a)
        expect(a / a).to eq(BLS::Fq2::ONE)
      end
    end
  end

  describe 'Fp2 division with zero equality' do
    it 'should pass division with zero equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(BLS::Fq2::ZERO / a).to eq(BLS::Fq2::ZERO)
      end
    end
  end

  describe 'Fp2 division distributivity' do
    it 'should pass division distributivity.' do
      NUM_RUNS.times do
        a, b, c = create_fq2_items(3)
        expect((a + b) / c).to eq(a / c + b / c)
      end
    end
  end

  describe 'Fp2 addition with zero equality' do
    it 'should pass addition with zero equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a + BLS::Fq2::ZERO).to eq(a)
      end
    end
  end

  describe 'Fp2 addition commutativity' do
    it 'should pass addition commutativity.' do
      NUM_RUNS.times do
        a, b = create_fq2_items(2)
        expect(a + b).to eq(b + a)
      end
    end
  end

  describe 'Fp2 add associativity' do
    it 'should pass add associativity.' do
      NUM_RUNS.times do
        a, b, c = create_fq2_items(3)
        expect(a + (b + c)).to eq(a + b + c)
      end
    end
  end

  describe 'Fp2 minus zero equality' do
    it 'should pass minus zero equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a - BLS::Fq2::ZERO).to eq(a)
        expect(a - a).to eq(BLS::Fq2::ZERO)
      end
    end
  end

  describe 'Fp2 minus and negative equality' do
    it 'should pass minus and negative equality.' do
      NUM_RUNS.times do
        a, b = create_fq2_items(2)
        expect(BLS::Fq2::ZERO - a).to eq(a.negate)
        expect(a - b).to eq(a + b.negate)
        expect(a - b).to eq(a + b * -1)
      end
    end
  end

  describe 'Fp2 negative equality' do
    it 'should pass negative equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a.negate).to eq(BLS::Fq2::ZERO - a)
        expect(a.negate).to eq(a * -1)
      end
    end
  end

  describe 'Fp2 division and multiplication equality' do
    it 'should pass division and multiplication equality.' do
      NUM_RUNS.times do
        a, b = create_fq2_items(2)
        expect(a / b).to eq(a * b.invert)
      end
    end
  end

  describe 'Fp2 pow and multiplication equality' do
    it 'should pass pow and multiplication equality.' do
      NUM_RUNS.times do
        a = create_fq2_items(1)
        expect(a**0).to eq(BLS::Fq2::ONE)
        expect(a**1).to eq(a)
        expect(a**2).to eq(a * a)
        expect(a**3).to eq(a * a * a)
      end
    end
  end
end
