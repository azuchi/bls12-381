# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BLS::Error do

  # These three used to be siblings under StandardError, so `rescue BLS::Error` quietly let a
  # rejected point or an undefined pairing through.
  it 'is what the other two descend from' do
    expect(BLS::PointError.ancestors).to include(BLS::Error)
    expect(BLS::PairingError.ancestors).to include(BLS::Error)
    expect(BLS::Error.ancestors).to include(StandardError)
  end

  it 'covers everything raised about the given data' do
    {
      BLS::PointError => [
        -> { BLS::PointG1.from_hex('ff' * 48) },        # not in the subgroup
        -> { BLS::PointG2.from_hex('') },               # wrong length
        -> { BLS::PointG1.hash_to_curve('zz') },        # not hex
        -> { BLS::PointG1::ZERO.to_affine_batch([BLS::PointG1::ZERO]) }
      ],
      BLS::PairingError => [-> { BLS.pairing(BLS::PointG1::ZERO, BLS::PointG2::BASE) }],
      BLS::Error => [
        -> { BLS.normalize_priv_key('abcXYZ') },
        -> { BLS::Fp::ZERO.invert },
        -> { BLS.sign('aabb', 5, scheme: :unknown) }
      ]
    }.each do |klass, cases|
      cases.each do |raising|
        expect { raising.call }.to raise_error(klass)
        expect { raising.call }.to raise_error(BLS::Error)
      end
    end
  end

  # A caller passing the wrong type has made a mistake in their own code, which is what
  # ArgumentError is for, so those stay outside the hierarchy.
  it 'leaves argument mistakes as ArgumentError' do
    expect { BLS::Fp.new('x') }.to raise_error(ArgumentError)
    expect { BLS::Fp2.new([1, 2, 3]) }.to raise_error(ArgumentError)
    expect { BLS.pairing(1, 2) }.to raise_error(ArgumentError)
  end
end
