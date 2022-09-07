# frozen_string_literal: true

require 'securerandom'

RSpec.describe 'bls12-381' do

  before do
    BLS::PointG1::BASE.clear_multiply_precomputes
    BLS::PointG1::BASE.calc_multiply_precomputes(8)
  end

  it 'should construct point G1 from its uncompressed form (Hex)' do
    # Test Zero
    g1 = BLS::PointG1.from_hex('400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')
    expect(g1.x).to eq(BLS::PointG1::ZERO.x)
    expect(g1.y).to eq(BLS::PointG1::ZERO.y)
    # Test Non-Zero
    x = BLS::Fq.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb)
    y = BLS::Fq.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1)
    g1 = BLS::PointG1.from_hex('17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1')
    expect(g1.x).to eq(x)
    expect(g1.y).to eq(y)
  end

  it 'should construct point G2 from its uncompressed form (Hex)' do
    # Test Zero
    g2 = BLS::PointG2.from_hex('400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')
    expect(g2.x).to eq(BLS::PointG2::ZERO.x)
    expect(g2.y).to eq(BLS::PointG2::ZERO.y)
    # Test Non-Zero
    x = BLS::Fq2.new([
                       0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                       0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e])
    y = BLS::Fq2.new([
                       0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801,
                       0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be])
    g2 = BLS::PointG2.from_hex('13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801')
    expect(g2.x).to eq(x)
    expect(g2.y).to eq(y)
  end

  it 'should get uncompressed form of point G1 (Hex)' do
    # Test Zero
    expect(BLS::PointG1::ZERO.to_hex).to eq('400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')
    # Test Non-Zero
    x = BLS::Fq.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb)
    y = BLS::Fq.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1)
    g1 = BLS::PointG1.new(x, y, BLS::Fq::ONE)
    expect(g1.to_hex).to eq('17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1')
  end

  it 'should get uncompressed form of point G2 (Hex)' do
    expect(BLS::PointG2::ZERO.to_hex).to eq('400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')
    # Test Non-Zero
    x = BLS::Fq2.new([
                       0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                       0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e])
    y = BLS::Fq2.new([
                       0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801,
                       0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be])
    g2 = BLS::PointG2.new(x, y, BLS::Fq2::ONE)
    expect(g2.to_hex).to eq('13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801')
  end

  it 'should compress and decompress G1 points' do
    priv = BLS::PointG1.from_private_key(42)
    public_key = priv.to_hex(compressed: true)
    decomp = BLS::PointG1.from_hex(public_key)
    expect(public_key).to eq(decomp.to_hex(compressed: true))
  end

  it 'should not compress and decompress zero G1 point' do
    expect{ BLS::PointG1.from_private_key(0) }.to raise_error(BLS::Error)
  end

  let(:g2_vectors) do
    vectors = fixture_file('bls12-381-g2-test-vectors.txt')
    vectors.split("\n").map { |v| v.split(':') }
  end

  it 'should produce correct signatures vectors)' do
    g2_vectors.each do |v|
      priv, msg, expected = v
      sig = BLS.sign(msg, priv)
      expect(sig.to_signature).to eq(expected)
      # Verify
      public_key = BLS.get_public_key(priv)
      expect(BLS.verify(sig, msg, public_key)).to be true
    end
  end

  it 'should not verify signature with wrong message' do
    NUM_RUNS.times do |i|
      priv, msg, = g2_vectors[i]
      inv_msg = g2_vectors[i + 1][1]
      sig = BLS.sign(msg, priv)
      pub = BLS.get_public_key(priv)
      expect(BLS.verify(sig, inv_msg, pub)).to be false
    end
  end

  it 'should not verify signature with wrong message' do
    NUM_RUNS.times do |i|
      priv, msg, = g2_vectors[i]
      sig = BLS.sign(msg, priv)
      inv_pub = BLS.get_public_key(g2_vectors[i + 1][1])
      expect(BLS.verify(sig, msg, inv_pub)).to be false
    end
  end

  it 'should verify multi-signature' do
    NUM_RUNS.times do
      vectors = rand(1..100).times.map do
        [SecureRandom.hex, rand(1..BLS::Curve::R)]
      end
      messages = vectors.map { |message, _| message }
      public_keys = vectors.map do |_, private_key|
        BLS.get_public_key(private_key)
      end
      signatures = vectors.map do |message, private_key|
        BLS.sign(message, private_key)
      end
      agg = BLS.aggregate_signatures(signatures)
      expect(BLS.verify_batch(agg, messages, public_keys)).to be true
    end
  end

  it 'should batch verify multi-signatures' do
    NUM_RUNS.times do
      vectors = rand(1..100).times.map do
        [SecureRandom.hex, SecureRandom.hex, rand(1..BLS::Curve::R)]
      end
      wrong_messages = vectors.map { |_, wrong_message, _| wrong_message }
      public_keys = vectors.map do |_, _, private_key|
        BLS.get_public_key(private_key)
      end
      signatures = vectors.map do |message, _, private_key|
        BLS.sign(message, private_key)
      end
      agg = BLS.aggregate_signatures(signatures)
      expect(BLS.verify_batch(agg, wrong_messages, public_keys)).to be false
    end
  end

  it 'README.md test.' do
    message = '64726e3da8'
    private_keys = %w[18f020b98eb798752a50ed0563b079c125b0db5dd0b1060d1c1b47d4a193e1e4 ed69a8c50cf8c9836be3b67c7eeff416612d45ba39a5c099d48fa668bf558c9c 16ae669f3be7a2121e17d0c68c05a8f3d6bef21ec0f2315f1d7aec12484e4cf5]
    public_keys = private_keys.map { |p| BLS.get_public_key(p) }

    signature2 = private_keys.map { |p| BLS.sign(message, p) }
    agg_public_keys2 = BLS.aggregate_public_keys(public_keys)
    agg_signatures2 = BLS.aggregate_signatures(signature2)
    expect(BLS.verify(agg_signatures2, message, agg_public_keys2)).to be true

    messages = %w[d2 0d98 05caf3]
    signatures3 = private_keys.map.with_index { |p, i| BLS.sign(messages[i], p)}
    agg_signatures3 = BLS.aggregate_signatures(signatures3)
    expect(BLS.verify_batch(agg_signatures3, messages, public_keys)).to be true
  end

  describe '#paring' do
    it 'has bilinear property' do
      a = 123
      b = 345

      aP = BLS::PointG1.from_private_key(a)
      bQ = BLS::PointG2.from_private_key(b)
      paring1 = BLS.pairing(aP, bQ)

      bP = BLS::PointG1.from_private_key(b)
      aQ = BLS::PointG2.from_private_key(a)

      paring2 = BLS.pairing(bP, aQ)
      expect(paring1).to eq(paring2)
    end
  end
end
