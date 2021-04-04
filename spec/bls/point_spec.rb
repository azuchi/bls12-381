# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Point' do

  describe 'Point with Fq coordinates' do

    it 'Point equality' do
      NUM_RUNS.times do
        p1, p2 = create_point_g1_items(2)
        expect(p1).to eq(p1)
        expect(p2).to eq(p2)
        expect(p1).not_to eq(p2)
        expect(p2).not_to eq(p1)
      end
    end

    it 'should be placed on curve vector 1' do
      a = BLS::PointG1.new(BLS::Fq.new(0), BLS::Fq.new(1), BLS::Fq.new(0))
      expect { a.validate! }.not_to raise_error(BLS::PointError)
    end

    it 'should be placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fq.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb),
        BLS::Fq.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fq.new(1)
      )
      expect { a.validate! }.not_to raise_error(BLS::PointError)
    end

    it 'should be placed on curve vector 3' do
      a = BLS::PointG1.new(
        BLS::Fq.new(3924344720014921989021119511230386772731826098545970939506931087307386672210285223838080721449761235230077903044877),
        BLS::Fq.new(849807144208813628470408553955992794901182511881745746883517188868859266470363575621518219643826028639669002210378),
        BLS::Fq.new(3930721696149562403635400786075999079293412954676383650049953083395242611527429259758704756726466284064096417462642)
      )
      expect { a.validate! }.not_to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 1' do
      a = BLS::PointG1.new(BLS::Fq.new(0), BLS::Fq.new(1), BLS::Fq.new(1))
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fq.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6ba),
        BLS::Fq.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fq.new(1)
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 3' do
      a = BLS::PointG1.new(
        BLS::Fq.new(0x034a6fce17d489676fb0a38892584cb4720682fe47c6dc2e058811e7ba4454300c078d0d7d8a147a294b8758ef846cca),
        BLS::Fq.new(0x14e4b429606d02bc3c604c0410e5fc01d6093a00bb3e2bc9395952af0b6a0dbd599a8782a1bea48a2aa4d8e1b1df7caa),
        BLS::Fq.new(0x1167e903c75541e3413c61dae83b15c9f9ebc12baba015ec01b63196580967dba0798e89451115c8195446528d8bcfca)
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should be doubled and placed on curve vector 1' do
      a = BLS::PointG1.new(
        BLS::Fq.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb),
        BLS::Fq.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fq.new(1)
      )
      double = a.double
      expect { double.validate! }.not_to raise_error(BLS::PointError)
      expect(double).to eq(BLS::PointG1.new(
                             BLS::Fq.new(0x5dff4ac6726c6cb9b6d4dac3f33e92c062e48a6104cc52f6e7f23d4350c60bd7803e16723f9f1478a13c2b29f4325ad),
                             BLS::Fq.new(0x14e4b429606d02bc3c604c0410e5fc01d6093a00bb3e2bc9395952af0b6a0dbd599a8782a1bea48a2aa4d8e1b1df7ca5),
                             BLS::Fq.new(0x430df56ea4aba6928180e61b1f2cb8f962f5650798fdf279a55bee62edcdb27c04c720ae01952ac770553ef06aadf22)
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end

    it 'should be doubled and placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fq.new(3924344720014921989021119511230386772731826098545970939506931087307386672210285223838080721449761235230077903044877),
        BLS::Fq.new(849807144208813628470408553955992794901182511881745746883517188868859266470363575621518219643826028639669002210378),
        BLS::Fq.new(3930721696149562403635400786075999079293412954676383650049953083395242611527429259758704756726466284064096417462642)
      )
      double = a.double
      expect { double.validate! }.not_to raise_error(BLS::PointError)
      expect(double).to eq(BLS::PointG1.new(
        BLS::Fq.new(1434314241472461137481482360511979492412320309040868403221478633648864894222507584070840774595331376671376457941809),
        BLS::Fq.new(1327071823197710441072036380447230598536236767385499051709001927612351186086830940857597209332339198024189212158053),
        BLS::Fq.new(3846649914824545670119444188001834433916103346657636038418442067224470303304147136417575142846208087722533543598904)
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end
  end

end
