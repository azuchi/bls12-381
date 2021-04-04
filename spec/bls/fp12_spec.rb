# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Fp12' do

  it 'Fp12 equality' do
    NUM_RUNS.times do
      nums = 12.times.map { rand(1..BLS::Fq::ORDER) }
      a = BLS::Fq12.from_tuple(nums)
      b = BLS::Fq12.from_tuple(nums)
      expect(a).to eq(b)
    end
  end

  it 'Fp12 non-equality' do
    NUM_RUNS.times do
      num1 = 12.times.map { rand(1..BLS::Fq::ORDER) }
      num2 = 12.times.map { rand(1..BLS::Fq::ORDER) }
      a = BLS::Fq12.from_tuple(num1)
      b = BLS::Fq12.from_tuple(num2)
      expect(a == b).to eq(num1[0] == num2[0] && num1[1] == num2[1])
      expect(b == a).to eq(num1[0] == num2[0] && num1[1] == num2[1])
    end
  end

  it 'Fp12 square and multiplication equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a.square).to eq(a * a)
    end
  end

  it 'Fp12 multiplication and add equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a * 0).to eq(BLS::Fq12::ZERO)
      expect(a * BLS::Fq12::ZERO).to eq(BLS::Fq12::ZERO)
      expect(a * 1).to eq(a)
      expect(a * BLS::Fq12::ONE).to eq(a)
      expect(a * 2).to eq(a + a)
      expect(a * 3).to eq(a + a + a)
      expect(a * 4).to eq(a + a + a + a)
    end
  end

  it 'Fp12 multiplication commutativity' do
    NUM_RUNS.times do
      a, b = create_fq12_items(2)
      expect(a * b).to eq(b * a)
    end
  end

  it 'Fp12 multiplication associativity' do
    NUM_RUNS.times do
      a, b, c = create_fq12_items(3)
      expect(a * (b * c)).to eq(a * b * c)
    end
  end

  it 'Fp12 multiplication distributivity' do
    NUM_RUNS.times do
      a, b, c = create_fq12_items(3)
      expect(a * (b + c)).to eq(a * b + a * c)
    end
  end

  it 'Fp12 division with one equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a / 1).to eq(a)
      expect(a / BLS::Fq12::ONE).to eq(a)
      expect(a / a).to eq(BLS::Fq12::ONE)
    end
  end

  it 'Fp12 division with zero equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(BLS::Fq12::ZERO / a).to eq(BLS::Fq12::ZERO)
    end
  end

  it 'Fp12 division distributivity' do
    NUM_RUNS.times do
      a, b, c = create_fq12_items(3)
      expect((a + b) / c).to eq(a / c + b / c)
    end
  end

  it 'Fp12 addition with zero equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a + BLS::Fq12::ZERO).to eq(a)
    end
  end

  it 'Fp12 addition commutativity' do
    NUM_RUNS.times do
      a, b = create_fq12_items(2)
      expect(a + b).to eq(b + a)
    end
  end

  it 'Fp12 add associativity' do
    NUM_RUNS.times do
      a, b, c = create_fq12_items(3)
      expect(a + (b + c)).to eq(a + b + c)
    end
  end

  it 'Fp12 minus zero equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a - BLS::Fq12::ZERO).to eq(a)
      expect(a - a).to eq(BLS::Fq12::ZERO)
    end
  end

  it 'Fp12 minus and negative equality' do
    NUM_RUNS.times do
      a, b = create_fq12_items(2)
      expect(BLS::Fq12::ZERO - a).to eq(a.negate)
      expect(a - b).to eq(a + b.negate)
      expect(a - b).to eq(a + b * -1)
    end
  end

  it 'Fp12 negative equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a.negate).to eq(BLS::Fq12::ZERO - a)
      expect(a.negate).to eq(a * -1)
    end
  end

  it 'Fp12 division and multiplication equality' do
    NUM_RUNS.times do
      a, b = create_fq12_items(2)
      expect(a / b).to eq(a * b.invert)
    end
  end

  it 'Fp12 pow and multiplication equality' do
    NUM_RUNS.times do
      a = create_fq12_items(1)
      expect(a**0).to eq(BLS::Fq12::ONE)
      expect(a**1).to eq(a)
      expect(a**2).to eq(a * a)
      expect(a**3).to eq(a * a * a)
    end
  end
end
