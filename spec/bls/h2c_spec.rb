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

    it 'produces different output for different tags' do
      msg = '00' * 32
      basic = BLS::H2C.expand_message_xmd(msg, 32, BLS::PointG2::DST_BASIC)
      pop = BLS::H2C.expand_message_xmd(msg, 32, BLS::PointG2::DST_POP)
      expect(basic).not_to eq(pop)
    end
  end
end
