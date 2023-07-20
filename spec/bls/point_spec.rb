# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'bls12-381 Point' do

  describe 'Point with Fp coordinates' do

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
      a = BLS::PointG1.new(BLS::Fp.new(0), BLS::Fp.new(1), BLS::Fp.new(0))
      expect { a.validate! }.not_to raise_error
    end

    it 'should be placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fp.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb),
        BLS::Fp.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fp.new(1)
      )
      expect { a.validate! }.not_to raise_error
    end

    it 'should be placed on curve vector 3' do
      a = BLS::PointG1.new(
        BLS::Fp.new(3924344720014921989021119511230386772731826098545970939506931087307386672210285223838080721449761235230077903044877),
        BLS::Fp.new(849807144208813628470408553955992794901182511881745746883517188868859266470363575621518219643826028639669002210378),
        BLS::Fp.new(3930721696149562403635400786075999079293412954676383650049953083395242611527429259758704756726466284064096417462642)
      )
      expect { a.validate! }.not_to raise_error
    end

    it 'should not be placed on curve vector 1' do
      a = BLS::PointG1.new(BLS::Fp.new(0), BLS::Fp.new(1), BLS::Fp.new(1))
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fp.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6ba),
        BLS::Fp.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fp.new(1)
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 3' do
      a = BLS::PointG1.new(
        BLS::Fp.new(0x034a6fce17d489676fb0a38892584cb4720682fe47c6dc2e058811e7ba4454300c078d0d7d8a147a294b8758ef846cca),
        BLS::Fp.new(0x14e4b429606d02bc3c604c0410e5fc01d6093a00bb3e2bc9395952af0b6a0dbd599a8782a1bea48a2aa4d8e1b1df7caa),
        BLS::Fp.new(0x1167e903c75541e3413c61dae83b15c9f9ebc12baba015ec01b63196580967dba0798e89451115c8195446528d8bcfca)
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should be doubled and placed on curve vector 1' do
      a = BLS::PointG1.new(
        BLS::Fp.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb),
        BLS::Fp.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1),
        BLS::Fp.new(1)
      )
      double = a.double
      expect { double.validate! }.not_to raise_error
      expect(double).to eq(BLS::PointG1.new(
                             BLS::Fp.new(0x5dff4ac6726c6cb9b6d4dac3f33e92c062e48a6104cc52f6e7f23d4350c60bd7803e16723f9f1478a13c2b29f4325ad),
                             BLS::Fp.new(0x14e4b429606d02bc3c604c0410e5fc01d6093a00bb3e2bc9395952af0b6a0dbd599a8782a1bea48a2aa4d8e1b1df7ca5),
                             BLS::Fp.new(0x430df56ea4aba6928180e61b1f2cb8f962f5650798fdf279a55bee62edcdb27c04c720ae01952ac770553ef06aadf22)
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end

    it 'should be doubled and placed on curve vector 2' do
      a = BLS::PointG1.new(
        BLS::Fp.new(3924344720014921989021119511230386772731826098545970939506931087307386672210285223838080721449761235230077903044877),
        BLS::Fp.new(849807144208813628470408553955992794901182511881745746883517188868859266470363575621518219643826028639669002210378),
        BLS::Fp.new(3930721696149562403635400786075999079293412954676383650049953083395242611527429259758704756726466284064096417462642)
      )
      double = a.double
      expect { double.validate! }.not_to raise_error
      expect(double).to eq(BLS::PointG1.new(
                             BLS::Fp.new(1434314241472461137481482360511979492412320309040868403221478633648864894222507584070840774595331376671376457941809),
                             BLS::Fp.new(1327071823197710441072036380447230598536236767385499051709001927612351186086830940857597209332339198024189212158053),
                             BLS::Fp.new(3846649914824545670119444188001834433916103346657636038418442067224470303304147136417575142846208087722533543598904)
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end
  end

  describe 'Point with Fp2 coordinates' do

    it 'Point equality' do
      NUM_RUNS.times do
        p1, p2 = create_point_g2_items(2)
        expect(p1).to eq(p1)
        expect(p2).to eq(p2)
        expect(p1).not_to eq(p2)
        expect(p2).not_to eq(p1)
      end
    end

    it 'should be placed on curve vector 1' do
      a = BLS::PointG2.new(BLS::Fp2.new([0, 0]), BLS::Fp2.new([1, 0]), BLS::Fp2.new([0, 0]))
      expect { a.validate! }.not_to raise_error
    end

    it 'should be placed on curve vector 2' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                      0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e]),
        BLS::Fp2.new([0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801,
                      0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be]),
        BLS::Fp2.new([1, 0])
      )
      expect { a.validate! }.not_to raise_error
    end

    it 'should be placed on curve vector 3' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([1050910533020938551374635094591786195161318899082245208049526631521590440770333461074893697611276887218497078796422,
                      1598996588129879649144273449445099511963892936268948685794588663059536473334389899700849905658337146716739117116278]),
        BLS::Fp2.new([2297925586785011392322632866903098777630933241582428655157725630032766380748347103951287973711001282071754690744592,
                      2722692942832192263619429510118606113750284957310697940719148392728935618099339326005363048966551031941723480961950]),
        BLS::Fp2.new([76217213143079476655331517031477221909850679220115226933444440112284563392888424587575503026751093730973752137345,
                      651517437191775294694379224746298241572865421785132086369822391079440481283732426567988496860904675941017132063964])
      )
      expect { a.validate! }.not_to raise_error
    end

    it 'should not be placed on curve vector 1' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([0, 0]),
        BLS::Fp2.new([1, 0]),
        BLS::Fp2.new([1, 0])
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 2' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4410b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                      0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e]),
        BLS::Fp2.new([0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d229a695160d12c923ac9cc3baca289e193548608b82801,
                      0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be]),
        BLS::Fp2.new([1, 0])
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should not be placed on curve vector 3' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([0x877d52dd65245f8908a03288adcd396f489ef87ae23fe110c5aa48bc208fbd1a0ed403df5b1ac137922b915f1f38ec37,
                      0x0cf8158b9e689553d58194f79863fe02902c5f169f0d4ddf46e23f15bb4f24304a8e26f1e5febc57b750d1c3dc4261d8]),
        BLS::Fp2.new([0x065ae9215806e8a55fd2d9ec4af9d2d448599cdb85d9080b2c9b4766434c33d103730c92c30a69d0602a8804c2a7c65f,
                      0x0e9c342d8a6d4b3a1cbd02c7bdc0e0aa304de41a04569ae33184419e66bbc0271c361c973962955ba6405f0e51beb98b]),
        BLS::Fp2.new([0x19cbaa4ee4fadc2319939b8db45c6a355bfb3755197ba74eda8534d2a2c1a2592475939877594513c326a90c11705002,
                      0x0c0d89405d4e69986559a56057851733967c50fd0b4ec75e4ce92556ae5d33567e6e1a4eb9d83b4355520ebfe0bef37c])
      )
      expect { a.validate! }.to raise_error(BLS::PointError)
    end

    it 'should be doubled and placed on curve vector 1' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                      0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e]),
        BLS::Fp2.new([0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801,
                      0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be]),
        BLS::Fp2.new([1, 0])
      )
      double = a.double
      expect { a.validate! }.not_to raise_error
      expect(double).to eq(BLS::PointG2.new(
                             BLS::Fp2.new([2004569552561385659566932407633616698939912674197491321901037400001042336021538860336682240104624979660689237563240,
                                           3955604752108186662342584665293438104124851975447411601471797343177761394177049673802376047736772242152530202962941]),
                             BLS::Fp2.new([978142457653236052983988388396292566217089069272380812666116929298652861694202207333864830606577192738105844024927,
                                           2248711152455689790114026331322133133284196260289964969465268080325775757898907753181154992709229860715480504777099]),
                             BLS::Fp2.new([3145673658656250241340817105688138628074744674635286712244193301767486380727788868972774468795689607869551989918920,
                                           968254395890002185853925600926112283510369004782031018144050081533668188797348331621250985545304947843412000516197])
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end

    it 'should be doubled and placed on curve vector 2' do
      a = BLS::PointG2.new(
        BLS::Fp2.new([1050910533020938551374635094591786195161318899082245208049526631521590440770333461074893697611276887218497078796422,
                      1598996588129879649144273449445099511963892936268948685794588663059536473334389899700849905658337146716739117116278]),
        BLS::Fp2.new([2297925586785011392322632866903098777630933241582428655157725630032766380748347103951287973711001282071754690744592,
                      2722692942832192263619429510118606113750284957310697940719148392728935618099339326005363048966551031941723480961950]),
        BLS::Fp2.new([76217213143079476655331517031477221909850679220115226933444440112284563392888424587575503026751093730973752137345,
                      651517437191775294694379224746298241572865421785132086369822391079440481283732426567988496860904675941017132063964])
      )
      double = a.double
      expect { a.validate! }.not_to raise_error
      expect(double).to eq(BLS::PointG2.new(
        BLS::Fp2.new([971534195338026376106694691801988868863420444490100454506033572314651086872437977861235872590578590756720024471469,
                      378014958429131328675394810343769919858050810498061656943526952326849391332443820094459004368687076347500373099156]),
        BLS::Fp2.new([3280997195265200639128448910548139455469442645584276216556357555470480677955454794092224549507347100925189702190894,
                      158426171401258191330058082816753806149755104529779342689180332371855591641984107207983953003313468624083823672075]),
        BLS::Fp2.new([3008329035346660988655239603307628288451385710327841564719334330531972476116399444025767153235631811081036738463342,
                      3341599904620117102667473563202270732934028545405889777934923014103677543378240279263895401928203318430834551303601])
      ))
      expect(double).to eq(a * 2)
      expect(double).to eq(a + a)
    end

    let(:g) { BLS::PointG1::BASE.negate.negate }
    let(:keys) do
      [
        0x28b90deaf189015d3a325908c5e0e4bf00f84f7e639b056ff82d7e70b6eede4c,
        0x1a0111ea397fe69a4bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa,
        0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaa,
        0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa,
        0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab,
        0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaac
      ].freeze
    end

    it 'wNAF multiplication same as unsafe (G1, W=1)' do
      keys.each do |k|
        expect(g * k).to eq(g.multiply_unsafe(k))
      end
    end

    it 'wNAF multiplication same as unsafe (G1, W=4)' do
      g.calc_multiply_precomputes(4)
      keys.each do |k|
        expect(g * k).to eq(g.multiply_unsafe(k))
      end
    end

    it 'wNAF multiplication same as unsafe (G1, W=5)' do
      g.calc_multiply_precomputes(5)
      keys.each do |k|
        expect(g * k).to eq(g.multiply_unsafe(k))
      end
    end

    let(:g2) { BLS::PointG2::BASE.negate.negate }
    it 'wNAF multiplication same as unsafe (G2, W=1)' do
      keys.each do |k|
        expect(g2 * k).to eq(g2.multiply_unsafe(k))
      end
    end

    it 'wNAF multiplication same as unsafe (G2, W=4)' do
      g2.calc_multiply_precomputes(4)
      keys.each do |k|
        expect(g2 * k).to eq(g2.multiply_unsafe(k))
      end
    end

    it 'wNAF multiplication same as unsafe (G2, W=5)' do
      g2.calc_multiply_precomputes(5)
      keys.each do |k|
        expect(g2 * k).to eq(g2.multiply_unsafe(k))
      end
    end

    it 'PSI cofactor cleaning same as multiplication' do
      points = [
        BLS::PointG2.new(
          BLS::Fp2.new([0x19658bb3b27541a2cf4c24ffe2a329fff606add46e55dac0ccf6d03887fa5a4bfbe3f9dcb991cfa8a8cb00b1b08699c3,
                        0x0b2fd20060fc25842260db4c6e9c6f2c83f4ad14ac319fe513363b589f18eda5f02337cfe9b2b8b679d47e01be32275f]),
          BLS::Fp2.new([0x0276bdbbad87dcd9f78581c6e40ac42d8036115a617a283014acc0ec55137a5e6234862859bc61a6d55c1115493a940b,
                        0x15d90b5c373060751f0ff367f3b75770c3bf3dc8f6f4078325bc24a7b134e7a290442a6b612f913b5ac4a2c5dc6cddea]),
          BLS::Fp2.new([0x0a0adb13f08a7a54039373efa3d100f9760aa0efc1d494f4e8d82915345f72444b43c021ab8d32b9393db70a6f75e6e1,
                        0x19fbb8b214bd1368a21fbe627574a25e0157459480bbd3a3e7febe5fec82b9ef1cdf49d4c2f12e68d44429403106aede])),
        BLS::PointG2.new(
          BLS::Fp2.new([0x166c0c0103a81e8cbf85d645d9fa05a1e656f3ca19e6b7f13013f35ab0e1abf4650234da919dcbd99196b6daf7850f2f,
                        0x1095a6c628b95126cac07d2b0fc01a373ed72f88a52086c9e1563573b151f73678dfb959eb3859e9c923b9ce048afdf9]),
          BLS::Fp2.new([0x0f7c5242ffdb2f2fd325e0cd9dd233d85d3f01c54b4f5d13f06429167356946689c2a0ac323c6f5ad46689b3ed35d272,
                        0x1258a942709e1174f931eab9661ad1994b479e965c7434d7eb27c725da7ab431a32eb8859d58abde2a7a0f2a83601b12]),
          BLS::Fp2.new([0x1728e5c5e2db31e982cef972c1b7376fab10f787a374ad66be59645b42878fac60ffc7b46097853e7f47757312374bb1,
                        0x09b021454f2266f5c4faad3224712b985be5e30a861d6b15978eecdf92c9da19f775c7caa33c4d6f8eb2c7aef031e54c])),
        BLS::PointG2.new(
          BLS::Fp2.new([0x1050085832985ac2c91552a31aa11977c7cfaf77c8b41b88a1c2b959cdd2d3d95954ba2428bb6fe4a568d036b9634a23,
                        0x0ed2e0dc90b9b40b3742ca07f022638422530dce532c3c4620fae0ceb4dc3d926515da7f38f1757ec6c04b33ad77645a]),
          BLS::Fp2.new([0x15d5fb5f39a8ae95b96fddd198e4cda8211007391c7be57205d137bd58cc8a06b48cbec32b70c7053a00c96ffe091da9,
                        0x037a323cf0270c8e34200ead02e40f3a04096a9aa774415fe79049248bcb70ef2ccddf9d87db100ce52342e25030528f]),
          BLS::Fp2.new([0x12f017b2c2a30eeaf122036397b06f2e4ef82edd41fd735416dbd2be3b491c312af1639dffa9943e00c624dfbf6d347e,
                        0x0714a7544bae337f8959b865f8e0c36104655157f6649fd798e54afeb3fb24a62464f2659c7b0d0999b55f71a49e2f9c])),
        BLS::PointG2.new(
          BLS::Fp2.new([0x14918659c1a50a20b4c3b07c242442b005070f68fab64c4b801f812c3378dbdb584053a428affb79bcf9190618488999,
                        0x0c2540ba1076ab00629d8c0d60a6bcf88b770d27343447b7868418f98c2f97cd9af7c5a5a4dae409a9ddeeb36308d2ce]),
          BLS::Fp2.new([0x06010eb447078dcaabf8f537df2739c9011f716552ade5d7980258700872219610d3769e78a56a95f52afe3254a40aca,
                        0x07889027cb2dea1e5ecbefcd0bdc55816a6abfaa8a280df42339c6cc3ff6436c9f1008fa00911006151d71ddfe9ead2c]),
          BLS::Fp2.new([0x1711ccc0d10cf739fb2aacb3f8dbef07e1698523ed8a927fe171d25606ff2241c77e2ed2dbf695c138714efb5afd53c1,
                        0x06ba4615f5c63cf56b12a267850d02402d0c8fd3294b70b77b93b4ccb7b6f4bf15df501d0cafd70b039167c306f834df])),
        BLS::PointG2.new(
          BLS::Fp2.new([0x19658bb3b27541a2cf4c24ffe2a329fff606add46e55dac0ccf6d03887fa5a4bfbe3f9dcb991cfa8a8cb00b1b08699c3,
                        0x0b2fd20060fc25842260db4c6e9c6f2c83f4ad14ac319fe513363b589f18eda5f02337cfe9b2b8b679d47e01be32275f]),
          BLS::Fp2.new([0x0276bdbbad87dcd9f78581c6e40ac42d8036115a617a283014acc0ec55137a5e6234862859bc61a6d55c1115493a940b,
                        0x15d90b5c373060751f0ff367f3b75770c3bf3dc8f6f4078325bc24a7b134e7a290442a6b612f913b5ac4a2c5dc6cddea]),
          BLS::Fp2.new([0x0a0adb13f08a7a54039373efa3d100f9760aa0efc1d494f4e8d82915345f72444b43c021ab8d32b9393db70a6f75e6e1,
                        0x19fbb8b214bd1368a21fbe627574a25e0157459480bbd3a3e7febe5fec82b9ef1cdf49d4c2f12e68d44429403106aede]))
      ]
      points.each do |p|
        expect(p.multiply_unsafe(BLS::Curve::H_EFF)).to eq(BLS::PointG2.clear_cofactor(p))
      end
    end
  end

  describe 'compress/decompress' do
    it do
      10.times do
        priv = SecureRandom.hex(32)
        p1 = BLS::PointG1.from_private_key(priv)
        compressed_p1 = p1.to_hex(compressed: true)
        uncompressed_p1 = p1.to_hex
        expect(BLS::PointG1.from_hex(compressed_p1)).to eq(p1)
        expect(BLS::PointG1.from_hex(uncompressed_p1)).to eq(p1)

        priv = SecureRandom.hex(32)
        p2 = BLS::PointG2.from_private_key(priv)
        compressed_p2 = p2.to_hex(compressed: true)
        uncompressed_p2 = p2.to_hex
        expect(BLS::PointG2.from_hex(compressed_p2)).to eq(p2)
        expect(BLS::PointG2.from_hex(uncompressed_p2)).to eq(p2)
      end
    end
  end
end
