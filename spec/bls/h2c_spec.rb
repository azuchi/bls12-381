# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BLS::H2C do

  describe '#expand_message_xmd' do
    # RFC 9380 Appendix K.1, expand_message_xmd(SHA-256). Uses a tag unrelated to any BLS
    # ciphersuite, so it also pins down that the tag is taken from the argument.
    it 'matches the RFC 9380 test vectors' do
      dst = 'QUUX-V01-CS02-with-expander-SHA256-128'
      [
        ['', 0x20, '68a985b87eb6b46952128911f2a4412bbc302a9d759667f87f7a21d803f07235'],
        ['abc', 0x20, 'd8ccab23b5985ccea865c6c97b6e5b8350e794e603b4b97902f53a8a0d605615'],
        ['abcdef0123456789', 0x20, 'eff31487c770a893cfb36f912fbfcbff40d5661771ca4b2cb4eafe524333f5c1'],
        ['', 0x80, 'af84c27ccfd45d41914fdff5df25293e221afc53d8ad2ac06d5e3e29485dadbee0d121587713a3e0dd4d5e69e' \
                   '93eb7cd4f5df4cd103e188cf60cb02edc3edf18eda8576c412b18ffb658e3dd6ec849469b979d444cf7b2691' \
                   '1a08e63cf31f9dcc541708d3491184472c2c29bb749d4286b004ceb5ee6b9a7fa5b646c993f0ced']
      ].each do |msg, len_in_bytes, expected|
        result = BLS::H2C.expand_message_xmd(msg.unpack1('H*'), len_in_bytes, dst)
        expect(result.pack('C*').unpack1('H*')).to eq(expected)
      end
    end

    # RFC 9380 Appendix K.2, the same expander with a 256-byte tag. Being over 255 bytes, the
    # tag no longer fits its one-byte length field and section 5.3.3 has it hashed down under
    # a fixed prefix first. Before that was done here, the length byte simply failed to encode.
    it 'matches the RFC 9380 test vectors for a tag longer than 255 bytes' do
      dst = 'QUUX-V01-CS02-with-expander-SHA256-128-long-DST-' + '1' * 208
      expect(dst.bytesize).to eq(256)
      [
        ['', 0x20, 'e8dc0c8b686b7ef2074086fbdd2f30e3f8bfbd3bdf177f73f04b97ce618a3ed3'],
        ['abc', 0x20, '52dbf4f36cf560fca57dedec2ad924ee9c266341d8f3d6afe5171733b16bbb12'],
        ['abcdef0123456789', 0x20, '35387dcf22618f3728e6c686490f8b431f76550b0b2c61cbc1ce7001536f4521'],
        ['q128_' + 'q' * 128, 0x20, '01b637612bb18e840028be900a833a74414140dde0c4754c198532c3a0ba42bc'],
        ['', 0x80, '14604d85432c68b757e485c8894db3117992fc57e0e136f71ad987f789a0abc287c47876978e2388a02af86b1e8' \
                   'd1342e5ce4f7aaa07a87321e691f6fba7e0072eecc1218aebb89fb14a0662322d5edbd873f0eb35260145cd4e6' \
                   '4f748c5dfe60567e126604bcab1a3ee2dc0778102ae8a5cfd1429ebc0fa6bf1a53c36f55dfc'],
        ['abc', 0x80, '1a30a5e36fbdb87077552b9d18b9f0aee16e80181d5b951d0471d55b66684914aef87dbb3626eaabf5ded8cd06' \
                      '86567e503853e5c84c259ba0efc37f71c839da2129fe81afdaec7fbdc0ccd4c794727a17c0d20ff0ea55e1389d' \
                      '6982d1241cb8d165762dbc39fb0cee4474d2cbbd468a835ae5b2f20e4f959f56ab24cd6fe267']
      ].each do |msg, len_in_bytes, expected|
        result = BLS::H2C.expand_message_xmd(msg.unpack1('H*'), len_in_bytes, dst)
        expect(result.pack('C*').unpack1('H*')).to eq(expected)
      end
    end

    it 'hashes to a valid G2 point under a tag longer than 255 bytes' do
      long = 'x' * 300
      point = BLS::PointG2.hash_to_curve('aa', dst: long)
      expect { point.validate! }.not_to raise_error
      expect(point.in_group?).to be true
      # Hashing the tag, not truncating it: a tag that only differs past byte 255 still counts.
      expect(point).not_to eq(BLS::PointG2.hash_to_curve('aa', dst: long[0, 299] + 'y'))
      expect(point).not_to eq(BLS::PointG2.hash_to_curve('aa', dst: long[0, 255]))
    end

    # The loop that fills in blocks b_2 .. b_ell ran one block too far, so ell == 255, the
    # largest value RFC 9380 section 5.3.1 allows, overflowed the one-byte block counter and
    # failed, and every other length cost a SHA-256 more than it needed.
    it 'produces every length up to the RFC maximum with exactly one digest per block' do
      calls = 0
      counting = Module.new { define_method(:digest) { |*args| calls += 1; super(*args) } }
      Digest::SHA256.singleton_class.prepend(counting)
      begin
        [1, 32, 33, 256, 254 * 32, 255 * 32].each do |len|
          calls = 0
          expect(BLS::H2C.expand_message_xmd('00', len, 'QUUX').size).to eq(len)
          expect(calls).to eq((len + 31) / 32 + 1) # b_0 plus one per output block
        end
        expect { BLS::H2C.expand_message_xmd('00', 255 * 32 + 1, 'QUUX') }.to raise_error(BLS::Error, /xmd length/)
      ensure
        counting.send(:remove_method, :digest)
      end
    end

    it 'rejects an empty tag' do
      expect { BLS::H2C.expand_message_xmd('aabb', 32, '') }.to raise_error(BLS::Error, /must not be empty/)
    end

    it 'produces different output for different tags' do
      msg = '00' * 32
      basic = BLS::H2C.expand_message_xmd(msg, 32, BLS::PointG2::DST_BASIC)
      pop = BLS::H2C.expand_message_xmd(msg, 32, BLS::PointG2::DST_POP)
      expect(basic).not_to eq(pop)
    end
  end
end
