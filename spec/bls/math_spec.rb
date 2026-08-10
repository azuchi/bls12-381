# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BLS do

  describe '#normalize_priv_key' do
    def expect_rejected(key)
      expect { BLS.normalize_priv_key(key) }.to raise_error(BLS::Error)
    end

    # String#to_i(16) returns what it managed to read rather than failing, so a key with a
    # typo in it used to become a different and much smaller key, silently.
    it 'rejects a string that is not entirely hex' do
      ['abcXYZ', 'abc def', "abc\n123", '0x1234', 'zzzz', ''].each { |key| expect_rejected(key) }
    end

    it 'rejects anything that is neither a string nor an integer' do
      [nil, 1.5, :abc, ['abc']].each { |key| expect_rejected(key) }
    end

    it 'rejects a key outside the multiplicative group' do
      [0, -1, BLS::Curve::R, BLS::Curve::R * 2].each { |key| expect_rejected(key) }
    end

    it 'reads hex in either case, at any length' do
      expect(BLS.normalize_priv_key(42).value).to eq(42)
      expect(BLS.normalize_priv_key('abc').value).to eq(0xabc)
      expect(BLS.normalize_priv_key('ABC').value).to eq(0xabc)
      expect(BLS.normalize_priv_key('f').value).to eq(15)
    end

    # The test vectors carry keys above the order, so they have to keep working.
    it 'reduces a key at or above the group order' do
      expect(BLS.normalize_priv_key(BLS::Curve::R + 5).value).to eq(5)
      key = 'f' * 64
      expect(key.to_i(16)).to be >= BLS::Curve::R
      expect(BLS.verify(BLS.sign('aabb', key), 'aabb', BLS.get_public_key(key))).to be true
    end
  end
end
