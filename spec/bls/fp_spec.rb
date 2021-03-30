# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Fp' do

  describe 'Fp equality' do
    it 'should be equal.' do
      NUM_RUNS.times do
        num = rand(1..BLS::Fq::ORDER)
        a = BLS::Fq.new(num)
        b = BLS::Fq.new(num)
        expect(a).to eq(b)
        expect(b).to eq(a)
      end
    end
  end

  describe 'Fp non-equality' do
    it 'should not be equal.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a).not_to eq(b)
        expect(b).not_to eq(a)
      end
    end
  end

  describe 'Fp square and multiplication equality' do
    it 'should be equal.' do
      NUM_RUNS.times do
        num = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(num.square).to eq(num * num)
      end
    end
  end

  describe 'Fp multiplication and add equality' do
    it 'should be equal.' do
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
  end

  describe 'Fp multiplication commutativity' do
    it 'should pass commutativity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a * b).to eq(b * a)
      end
    end
  end

  describe 'Fp multiplication associativity' do
    it 'should pass associativity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a * (b * c)).to eq(a * b * c)
      end
    end
  end

  describe 'Fp multiplication distributivity' do
    it 'should pass distributivity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a * (b + c)).to eq(b * a + c * a)
      end
    end
  end

  describe 'Fp division with one equality' do
    it 'should division with one equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a / BLS::Fq::ONE).to eq(a)
        expect(a / a).to eq(BLS::Fq::ONE)
      end
    end
  end

  describe 'Fp division with.ZERO equality' do
    it 'should division with.ZERO equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(BLS::Fq::ZERO / a).to eq(BLS::Fq::ZERO)
      end
    end
  end

  describe 'Fp division distributivity' do
    it 'should pass distributivity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a.add(b).div(c)).to eq(a.div(c).add(b.div(c)))
      end
    end
  end

  describe 'Fp addition with.ZERO equality' do
    it 'should pass addition with.ZERO equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a + BLS::Fq::ZERO).to eq(a)
      end
    end
  end

  describe 'Fp addition commutativity' do
    it 'should pass commutativity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a + b).to eq(b + a)
      end
    end
  end

  describe 'Fp add associativity' do
    it 'should pass associativity.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        c = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a + (b + c)).to eq(a + b + c)
      end
    end
  end

  describe 'Fp minus.ZERO equality' do
    it 'should pass minus.ZERO equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a - BLS::Fq::ZERO).to eq(a)
        expect(a - a).to eq(BLS::Fq::ZERO)
      end
    end
  end

  describe 'Fp minus and negative equality' do
    it 'should pass minus and negative equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(BLS::Fq::ZERO - a).to eq(a.negate)
        expect(a - b).to eq(a + b.negate)
        expect(a - b).to eq(a + b * BLS::Fq.new(-1))
      end
    end
  end

  describe 'Fp negative equality' do
    it 'should pass negative equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a.negate).to eq(BLS::Fq::ZERO - a)
        expect(a.negate).to eq(a * BLS::Fq.new(-1))
      end
    end
  end

  describe 'Fp division and multiplication equality' do
    it 'should pass division and multiplication equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        b = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a / b).to eq(a * b.invert)
      end
    end
  end

  describe 'Fp pow and multiplication equality' do
    it 'should pass ow and multiplication equality.' do
      NUM_RUNS.times do
        a = BLS::Fq.new(rand(1..BLS::Fq::ORDER))
        expect(a**0).to eq(BLS::Fq::ONE)
        expect(a**1).to eq(a)
        expect(a**2).to eq(a * a)
        expect(a**3).to eq(a * a * a)
      end
    end
  end
end
