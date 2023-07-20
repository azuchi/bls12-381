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
end