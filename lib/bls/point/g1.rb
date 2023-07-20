module BLS
  class PointG1 < BLS::ProjectivePoint

    DST_BASIC = 'BLS_SIG_BLS12381G1_XMD:SHA-256_SSWU_RO_NUL_'

    KEY_SIZE_COMPRESSED = 48
    KEY_SIZE_UNCOMPRESSED = 96

    BASE = PointG1.new(Fp.new(Curve::G_X), Fp.new(Curve::G_Y), Fp::ONE)
    ZERO = PointG1.new(Fp::ONE, Fp::ONE, Fp::ZERO)
    MAX_BITS = Fp::MAX_BITS

    # Parse PointG1 from form hex.
    # @param [String] hex hex value of PointG1.
    # @return [PointG1]
    # @raise [BLS::PointError] Occurs when hex length does not match, or point does not on G1.
    def self.from_hex(hex)
      bytes = [hex].pack('H*')
      point = case bytes.bytesize
              when KEY_SIZE_COMPRESSED
                compressed_value = hex.to_i(16)
                b_flag = BLS.mod(compressed_value, POW_2_383) / POW_2_382
                return ZERO if b_flag == 1

                x = BLS.mod(compressed_value, POW_2_381)
                full_y = BLS.mod(x**3 + Fp.new(Curve::B).value, Curve::P)
                y = BLS.pow_mod(full_y, (Curve::P + 1) / 4, Curve::P)
                raise PointError, 'The given point is not on G1: y**2 = x**3 + b.' unless (BLS.pow_mod(y, 2, Curve::P) - full_y).zero?

                a_flag = BLS.mod(compressed_value, POW_2_382) / POW_2_381
                y = Curve::P - y unless ((y * 2) / Curve::P) == a_flag
                PointG1.new(Fp.new(x), Fp.new(y), Fp::ONE)
              when KEY_SIZE_UNCOMPRESSED
                return ZERO unless (bytes[0].unpack1('H*').to_i(16) & (1 << 6)).zero?

                x = bytes[0...PUBLIC_KEY_LENGTH].unpack1('H*').to_i(16)
                y = bytes[PUBLIC_KEY_LENGTH..-1].unpack1('H*').to_i(16)
                PointG1.new(Fp.new(x), Fp.new(y), Fp::ONE)
              else
                raise PointError, 'Invalid point G1, expected 48 or 96 bytes.'
              end
      point.validate!
      point
    end

    def to_hex(compressed: false)
      if compressed
        if self == PointG1::ZERO
          hex = POW_2_383 + POW_2_382
        else
          x, y = to_affine
          flag = (y.value * 2) / Curve::P
          hex = x.value + flag * POW_2_381 + POW_2_383
        end
        BLS.num_to_hex(hex, PUBLIC_KEY_LENGTH)
      else
        if self == PointG1::ZERO
          (1 << 6).to_s(16) + '00' * (2 * PUBLIC_KEY_LENGTH - 1)
        else
          x, y = to_affine
          BLS.num_to_hex(x.value, PUBLIC_KEY_LENGTH) + BLS.num_to_hex(y.value, PUBLIC_KEY_LENGTH)
        end
      end
    end

    # Parse Point from private key.
    # @param [String|Integer] private_key a private key with hex or number.
    # @return [PointG1] G1Point corresponding to private keys.
    # @raise [BLS::Error] Occur when the private key is zero.
    def self.from_private_key(private_key)
      BASE * BLS.normalize_priv_key(private_key)
    end

    # Convert hash to PointG1
    # @param [String] message a hash with hex format.
    # @return [BLS::PointG1] point.
    # @raise [BLS::PointError]
    def self.hash_to_curve(message)
      raise PointError, 'expected hex string' unless message[/^[a-fA-F0-9]*$/]

      h2c = ::H2C.get(::H2C::Suite::BLS12381G1_XMDSHA256_SWU_RO_, PointG1::DST_BASIC)
      p = h2c.digest([message].pack('H*'))

      PointG1.new(Fp.new(p.x), Fp.new(p.y), Fp::ONE)
    end

    # Validate this point whether on curve over Fp.
    # @raise [PointError] Occur when this point not on curve over Fp.
    def validate!
      b = Fp.new(Curve::B)
      return if zero?

      left = y.pow(2) * z - x.pow(3)
      right = b * z.pow(3)
      raise PointError, 'Invalid point: not on curve over Fp' unless left == right
    end

    # Sparse multiplication against precomputed coefficients.
    # @param [PointG2] p
    def miller_loop(p)
      BLS.miller_loop(p.pairing_precomputes, to_affine)
    end
  end

end