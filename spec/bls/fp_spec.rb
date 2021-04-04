# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Fp' do

  it 'Fp equality' do
    NUM_RUNS.times do
      num = rand(1..BLS::Fq::ORDER)
      a = BLS::Fq.new(num)
      b = BLS::Fq.new(num)
      expect(a).to eq(b)
      expect(b).to eq(a)
    end
  end

  it 'Fp non-equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a).not_to eq(b)
      expect(b).not_to eq(a)
    end
  end

  it 'Fp square and multiplication equality' do
    NUM_RUNS.times do
      num = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(num.square).to eq(num * num)
    end
  end

  it 'Fp multiplication and add equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a * BLS::Fq.new(0)).to eq(BLS::Fq::ZERO)
      expect(a * BLS::Fq::ZERO).to eq(BLS::Fq::ZERO)
      expect(a * BLS::Fq.new(1)).to eq(a)
      expect(a * BLS::Fq::ONE).to eq(a)
      expect(a * BLS::Fq.new(2)).to eq(a + a)
      expect(a * BLS::Fq.new(3)).to eq(a + a + a)
      expect(a * BLS::Fq.new(4)).to eq(a + a + a + a)
    end
  end

  it 'Fp multiplication commutativity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a * b).to eq(b * a)
    end
  end

  it 'Fp multiplication associativity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a * (b * c)).to eq(a * b * c)
    end
  end

  it 'Fp multiplication distributivity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a * (b + c)).to eq(b * a + c * a)
    end
  end

  it 'Fp division with one equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a / BLS::Fq::ONE).to eq(a)
      expect(a / a).to eq(BLS::Fq::ONE)
    end
  end

  it 'Fp division with.ZERO equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(BLS::Fq::ZERO / a).to eq(BLS::Fq::ZERO)
    end
  end

  it 'Fp division distributivity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a.add(b).div(c)).to eq(a.div(c).add(b.div(c)))
    end
  end

  it 'Fp addition with.ZERO equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a + BLS::Fq::ZERO).to eq(a)
    end
  end

  it 'Fp addition commutativity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a + b).to eq(b + a)
    end
  end

  it 'Fp add associativity' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a + (b + c)).to eq(a + b + c)
    end
  end

  it 'Fp minus.ZERO equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a - BLS::Fq::ZERO).to eq(a)
      expect(a - a).to eq(BLS::Fq::ZERO)
    end
  end

  it 'Fp minus and negative equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(BLS::Fq::ZERO - a).to eq(a.negate)
      expect(a - b).to eq(a + b.negate)
      expect(a - b).to eq(a + b * BLS::Fq.new(-1))
    end
  end

  it 'Fp negative equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a.negate).to eq(BLS::Fq::ZERO - a)
      expect(a.negate).to eq(a * BLS::Fq.new(-1))
    end
  end

  it 'Fp division and multiplication equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a / b).to eq(a * b.invert)
    end
  end

  it 'Fp pow and multiplication equality' do
    NUM_RUNS.times do
      a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
      expect(a**0).to eq(BLS::Fq::ONE)
      expect(a**1).to eq(a)
      expect(a**2).to eq(a * a)
      expect(a**3).to eq(a * a * a)
    end
  end
end
