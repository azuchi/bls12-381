# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Fp2' do

  it 'Fp2 equality' do
    NUM_RUNS.times do
      num1 = rand(1..BLS::Fq::ORDER)
      num2 = rand(1..BLS::Fq::ORDER)
      a = BLS::Fq2.new([num1, num2])
      b = BLS::Fq2.new([num1, num2])
      expect(a).to eq(b)
      expect(b).to eq(a)
    end
  end

  it 'Fp2 non-equality' do
    NUM_RUNS.times do
      num1 = [rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)]
      num2 = [rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)]
      a = BLS::Fq2.new([num1[0], num1[1]])
      b = BLS::Fq2.new([num2[0], num2[1]])
      expect(a == b).to eq(num1[0] == num2[0] && num1[1] == num2[1])
      expect(b == a).to eq(num1[0] == num2[0] && num1[1] == num2[1])
    end
  end

  it 'Fp2 square and multiplication equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a.square).to eq(a * a)
    end
  end

  it 'Fp2 multiplication and add equality' do
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

  it 'Fp2 multiplication commutativity' do
    NUM_RUNS.times do
      a, b = create_fq2_items(2)
      expect(a * b).to eq(b * a)
    end
  end

  it 'Fp2 multiplication associativity' do
    NUM_RUNS.times do
      a, b, c = create_fq2_items(3)
      expect(a * (b * c)).to eq(a * b * c)
    end
  end

  it 'Fp2 multiplication distributivity' do
    NUM_RUNS.times do
      a, b, c = create_fq2_items(3)
      expect(a * (b + c)).to eq(b * a + c * a)
    end
  end

  it 'Fp2 division with one equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a / BLS::Fq2.new([1, 0])).to eq(a)
      expect(a / BLS::Fq2::ONE).to eq(a)
      expect(a / a).to eq(BLS::Fq2::ONE)
    end
  end

  it 'Fp2 division with zero equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(BLS::Fq2::ZERO / a).to eq(BLS::Fq2::ZERO)
    end
  end

  it 'Fp2 division distributivity' do
    NUM_RUNS.times do
      a, b, c = create_fq2_items(3)
      expect((a + b) / c).to eq(a / c + b / c)
    end
  end

  it 'Fp2 addition with zero equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a + BLS::Fq2::ZERO).to eq(a)
    end
  end

  it 'Fp2 addition commutativity' do
    NUM_RUNS.times do
      a, b = create_fq2_items(2)
      expect(a + b).to eq(b + a)
    end
  end

  it 'Fp2 add associativity' do
    NUM_RUNS.times do
      a, b, c = create_fq2_items(3)
      expect(a + (b + c)).to eq(a + b + c)
    end
  end

  it 'Fp2 minus zero equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a - BLS::Fq2::ZERO).to eq(a)
      expect(a - a).to eq(BLS::Fq2::ZERO)
    end
  end

  it 'Fp2 minus and negative equality' do
    NUM_RUNS.times do
      a, b = create_fq2_items(2)
      expect(BLS::Fq2::ZERO - a).to eq(a.negate)
      expect(a - b).to eq(a + b.negate)
      expect(a - b).to eq(a + b * -1)
    end
  end

  it 'Fp2 negative equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a.negate).to eq(BLS::Fq2::ZERO - a)
      expect(a.negate).to eq(a * -1)
    end
  end

  it 'Fp2 division and multiplication equality' do
    NUM_RUNS.times do
      a, b = create_fq2_items(2)
      expect(a / b).to eq(a * b.invert)
    end
  end

  it 'Fp2 pow and multiplication equality' do
    NUM_RUNS.times do
      a = create_fq2_items(1)
      expect(a**0).to eq(BLS::Fq2::ONE)
      expect(a**1).to eq(a)
      expect(a**2).to eq(a * a)
      expect(a**3).to eq(a * a * a)
    end
  end

  it 'Fp2 frobenius' do
    expect(BLS::Fq2::FROBENIUS_COEFFICIENTS[0]).to eq(BLS::Fq::ONE)
    expect(BLS::Fq2::FROBENIUS_COEFFICIENTS[1]).to eq(BLS::Fq::ONE.negate.pow(0x0f81ae6945026025546c75a2a5240311d8ab75fac730cbcacd117de46c663f3fdebb76c445078281bf953ed363fa069b))
    a = BLS::Fq2.new([
                       0x00f8d295b2ded9dcccc649c4b9532bf3b966ce3bc2108b138b1a52e0a90f59ed11e59ea221a3b6d22d0078036923ffc7,
                       0x012d1137b8a6a8374e464dea5bcfd41eb3f8afc0ee248cadbe203411c66fb3a5946ae52d684fa7ed977df6efcdaee0db])
    a = a.frobenius_map(0)
    expect(a).to eq(BLS::Fq2.new([0x00f8d295b2ded9dcccc649c4b9532bf3b966ce3bc2108b138b1a52e0a90f59ed11e59ea221a3b6d22d0078036923ffc7, 0x012d1137b8a6a8374e464dea5bcfd41eb3f8afc0ee248cadbe203411c66fb3a5946ae52d684fa7ed977df6efcdaee0db]))
    a = a.frobenius_map(1)
    expect(a).to eq(BLS::Fq2.new([0x00f8d295b2ded9dcccc649c4b9532bf3b966ce3bc2108b138b1a52e0a90f59ed11e59ea221a3b6d22d0078036923ffc7, 0x18d400b280d93e62fcd559cbe77bd8b8b07e9bc405608611a9109e8f3041427e8a411ad149045812228109103250c9d0]))
    a = a.frobenius_map(1)
    expect(a).to eq(BLS::Fq2.new([0x00f8d295b2ded9dcccc649c4b9532bf3b966ce3bc2108b138b1a52e0a90f59ed11e59ea221a3b6d22d0078036923ffc7, 0x012d1137b8a6a8374e464dea5bcfd41eb3f8afc0ee248cadbe203411c66fb3a5946ae52d684fa7ed977df6efcdaee0db]))
    a = a.frobenius_map(2)
    expect(a).to eq(BLS::Fq2.new([0x00f8d295b2ded9dcccc649c4b9532bf3b966ce3bc2108b138b1a52e0a90f59ed11e59ea221a3b6d22d0078036923ffc7, 0x012d1137b8a6a8374e464dea5bcfd41eb3f8afc0ee248cadbe203411c66fb3a5946ae52d684fa7ed977df6efcdaee0db]))
  end
end
