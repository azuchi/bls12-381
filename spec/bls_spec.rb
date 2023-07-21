# frozen_string_literal: true

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
    x = BLS::Fp.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb)
    y = BLS::Fp.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1)
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
    x = BLS::Fp2.new([
                       0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                       0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e])
    y = BLS::Fp2.new([
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
    x = BLS::Fp.new(0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb)
    y = BLS::Fp.new(0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1)
    g1 = BLS::PointG1.new(x, y, BLS::Fp::ONE)
    expect(g1.to_hex).to eq('17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1')
  end

  it 'should get uncompressed form of point G2 (Hex)' do
    expect(BLS::PointG2::ZERO.to_hex).to eq('400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000')
    # Test Non-Zero
    x = BLS::Fp2.new([
                       0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
                       0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e])
    y = BLS::Fp2.new([
                       0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801,
                       0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be])
    g2 = BLS::PointG2.new(x, y, BLS::Fp2::ONE)
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

  describe '#sign' do
    context "G1 public key and G2 Signature" do
      it 'should produce correct signatures vectors' do
        g2_vectors.each do |v|
          priv, msg, expected = v
          sig = BLS.sign(msg, priv)
          expect(sig.to_signature).to eq(expected)
          # Verify
          public_key = BLS.get_public_key(priv)
          expect(BLS.verify(sig, msg, public_key)).to be true
        end
      end
    end

    context "G2 public key and G1 signature" do
      it 'should produce correct signatures vectors' do
        priv = '6f3977f6051e184b2c412daa1b5c0115ef7ab347cac8d808ffa2c26bd0658243'
        msg = '50484522ad8aede64ec7f86b9273b7ed3940481acf93cdd40a2b77f2be2734a14012b2492b6363b12adaeaf055c573e4611b085d2e0fe2153d72453a95eaebf350ac3ba6a26ba0bc79f4c0bf5664dfdf5865f69f7fc6b58ba7d068e8'
        sig = BLS.sign(msg, priv, sig_type: :g1)
        expect(sig.to_hex(compressed: true )).to eq('8f7ad830632657f7b3eae17fd4c3d9ff5c13365eea8d33fd0a1a6d8fbebc5152e066bb0ad61ab64e8a8541c8e3f96de9')
      end
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
      vectors = rand(1..10).times.map do
        [SecureRandom.hex, rand(1..BLS::Curve::R)]
      end
      messages = vectors.map { |message, _| message }
      # signature is G2
      public_keys = vectors.map do |_, private_key|
        BLS.get_public_key(private_key)
      end
      signatures = vectors.map do |message, private_key|
        BLS.sign(message, private_key)
      end
      agg = BLS.aggregate_signatures(signatures)
      expect(BLS.verify_batch(agg, messages, public_keys)).to be true

      # signature is G1
      public_keys = vectors.map do |_, private_key|
        BLS.get_public_key(private_key, key_type: :g2)
      end
      signatures = vectors.map do |message, private_key|
        BLS.sign(message, private_key, sig_type: :g1)
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
      a = SecureRandom.bytes(32).unpack1('H*').to_i(16)
      b =  SecureRandom.bytes(32).unpack1('H*').to_i(16)

      aP = BLS::PointG1.from_private_key(a)
      bQ = BLS::PointG2.from_private_key(b)
      paring1 = BLS.pairing(aP, bQ)

      bP = BLS::PointG1.from_private_key(b)
      aQ = BLS::PointG2.from_private_key(a)

      paring2 = BLS.pairing(bP, aQ)
      expect(paring1).to eq(paring2)
    end
  end

  context 'Public key is G2 and Signature is G2' do
    context 'valid' do
      it do
        test_bls_signature(
          true,
          "ace9fcdd9bc977e05d6328f889dc4e7c99114c737a494653cb27a1f55c06f4555e0f160980af5ead098acc195010b2f7",
          "0d69632d73746174652d726f6f74e6c01e909b4923345ce5970962bcfe3004bfd8474a21dae28f50692502f46d90",
          "814c0e6ec71fab583b08bd81373c255c3c371b2e84863c98a4f1e08b74235d14fb5d9c0cd546d9685f913a0c0b2cc5341583bf4b4392e467db96d65b9bb4cb717112f8472e0d5a4d14505ffd7484b01291091c5f87b98883463f98091a0baaae");
        test_bls_signature(
          true,
          "89a2be21b5fa8ac9fab1527e041327ce899d7da971436a1f2165393947b4d942365bfe5488710e61a619ba48388a21b1",
          "0d69632d73746174652d726f6f74b294b418b11ebe5dd7dd1dcb099e4e0372b9a42aef7a7a37fb4f25667d705ea9",
          "9933e1f89e8a3c4d7fdcccdbd518089e2bd4d8180a261f18d9c247a52768ebce98dc7328a39814a8f911086a1dd50cbe015e2a53b7bf78b55288893daa15c346640e8831d72a12bdedd979d28470c34823b8d1c3f4795d9c3984a247132e94fe");
        test_bls_signature(
          true,
          "b1dd133edb8c9ee98e78449b5537e1b44e51d7807cbcf15b1f11eb08fc326da3a4e9b639131e985c01e27e1750ed7253",
          "0d69632d73746174652d726f6f742b2c26a884dbe39b122a1e4bf9bec9fac8d92b6d8e9f6d03f35b0d78cb3c3e1c",
          "b31b406c9f6648695a88154ae2e4f5fe87883d4ad81c2844c5571b2d91d401cdd40836e763a7c18dccb84629b0d808f7142c3175bc8231dc09bd53637efd6f2568801385ec973d34e6eef9c8c8280a9f4a114163a43a8540941ba367f0c7cb28");
      end
    end

    context 'invalid' do
      it do
        test_bls_signature(
          false,
          "89a2be21b5fa8ac9fab1527e041327ce899d7da971436a1f2165393947b4d942365bfe5488710e61a619ba48388a21b1",
          "0d69632d73746174652d726f6f74e6c01e909b4923345ce5970962bcfe3004bfd8474a21dae28f50692502f46d90",
          "814c0e6ec71fab583b08bd81373c255c3c371b2e84863c98a4f1e08b74235d14fb5d9c0cd546d9685f913a0c0b2cc5341583bf4b4392e467db96d65b9bb4cb717112f8472e0d5a4d14505ffd7484b01291091c5f87b98883463f98091a0baaae");

        test_bls_signature(
          false,
          "ace9fcdd9bc977e05d6328f889dc4e7c99114c737a494653cb27a1f55c06f4555e0f160980af5ead098acc195010b2f7",
          "0d69632d73746174652d726f6f74b294b418b11ebe5dd7dd1dcb099e4e0372b9a42aef7a7a37fb4f25667d705ea9",
          "9933e1f89e8a3c4d7fdcccdbd518089e2bd4d8180a261f18d9c247a52768ebce98dc7328a39814a8f911086a1dd50cbe015e2a53b7bf78b55288893daa15c346640e8831d72a12bdedd979d28470c34823b8d1c3f4795d9c3984a247132e94fe");

        # sig is not a valid point
        test_bls_signature(
          false,
          "ace9fcdd9bc977e05d6328f889dc4e7c99114c737a494653cb27a1f55c06f4555e0f160980af5ead098acc195010b2f8",
          "0d69632d73746174652d726f6f74e6c01e909b4923345ce5970962bcfe3004bfd8474a21dae28f50692502f46d90",
          "814c0e6ec71fab583b08bd81373c255c3c371b2e84863c98a4f1e08b74235d14fb5d9c0cd546d9685f913a0c0b2cc5341583bf4b4392e467db96d65b9bb4cb717112f8472e0d5a4d14505ffd7484b01291091c5f87b98883463f98091a0baaae");
      end
    end
  end

  def test_bls_signature(result, sig, msg, pubkey)
    sig = BLS::PointG1.from_hex(sig)
    pubkey = BLS::PointG2.from_hex(pubkey)
    expect(BLS.verify(sig, msg, pubkey)).to eq(result)
  end
end
