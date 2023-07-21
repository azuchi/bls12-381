module BLS
  class PointG2 < BLS::ProjectivePoint

    attr_accessor :precomputes

    DST_BASIC = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_'

    KEY_SIZE_COMPRESSED = 96
    KEY_SIZE_UNCOMPRESSED = 192

    MAX_BITS = Fp2::MAX_BITS
    BASE = PointG2.new(Fp2.new(Curve::G2_X), Fp2.new(Curve::G2_Y), Fp2::ONE)
    ZERO = PointG2.new(Fp2::ONE, Fp2::ONE, Fp2::ZERO)

    # Parse PointG2 from form hex.
    # https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-pairing-friendly-curves-07#section-appendix.c
    # @param [String] hex hex value of PointG2. Currently, only uncompressed formats(196 bytes) are supported.
    # @return [BLS::PointG2] PointG2.
    # @raise [BLS::PointError]
    def self.from_hex(hex)
      bytes = [hex].pack('H*')
      m_byte = bytes[0].unpack1('C')& 0xe0
      if [0x20, 0x60, 0xe0].include?(m_byte)
        raise PointError, "Invalid encoding flag: #{m_byte.to_s(16)}"
      end

      c_bit = m_byte & POINT_COMPRESSION_FLAG # compression flag
      i_bit = m_byte & POINT_INFINITY_FLAG # infinity flag
      s_bit = m_byte & POINT_Y_FLAG # y coordinate sign flag
      bytes[0] = [bytes[0].unpack1('C') & 0x1f].pack('C') # set flag to 0

      if i_bit == POINT_INFINITY_FLAG && bytes.unpack1('H*').to_i(16) > 0
        raise PointError, 'Invalid point, infinity point should be all 0.'
      end

      point = if bytes.bytesize == KEY_SIZE_COMPRESSED && c_bit == POINT_COMPRESSION_FLAG # compress format
                return ZERO if i_bit == POINT_INFINITY_FLAG
                x1 = bytes[0...PUBLIC_KEY_LENGTH].unpack1('H*').to_i(16)
                x0 = bytes[PUBLIC_KEY_LENGTH...(2 * PUBLIC_KEY_LENGTH)].unpack1('H*').to_i(16)
                x = Fp2.new([x0, x1])
                right = x ** 3 + Fp2.new(Curve::B2)
                y = right.sqrt
                raise PointError, 'Invalid compressed G2 point' unless y
                bit_y = if y.coeffs[1].value == 0
                          (y.coeffs[0].value * 2) / Curve::P
                        else
                          (y.coeffs[1].value * 2) / Curve::P == 1 ? 1 : 0
                        end
                y = s_bit > 0 && bit_y > 0 ? y : y.negate
                PointG2.new(x, y, Fp2::ONE)
              elsif bytes.bytesize == KEY_SIZE_UNCOMPRESSED && c_bit != POINT_COMPRESSION_FLAG # uncompressed format
                return ZERO if i_bit == POINT_INFINITY_FLAG
                x1 = bytes[0...PUBLIC_KEY_LENGTH].unpack1('H*').to_i(16)
                x0 = bytes[PUBLIC_KEY_LENGTH...(2 * PUBLIC_KEY_LENGTH)].unpack1('H*').to_i(16)
                y1 = bytes[(2 * PUBLIC_KEY_LENGTH)...(3 * PUBLIC_KEY_LENGTH)].unpack1('H*').to_i(16)
                y0 = bytes[(3 * PUBLIC_KEY_LENGTH)..-1].unpack1('H*').to_i(16)
                PointG2.new(Fp2.new([x0, x1]), Fp2.new([y0, y1]), Fp2::ONE)
              else
                raise PointError, 'Invalid point G2, expected 96/192 bytes.'
              end
      point.validate!
      point
    end

    # Parse Point from private key.
    # @param [String|Integer] private_key a private key with hex or number.
    # @return [PointG1] G1Point corresponding to private keys.
    # @raise [BLS::Error] Occur when the private key is zero.
    def self.from_private_key(private_key)
      BASE * BLS.normalize_priv_key(private_key)
    end

    # Convert hash to PointG2
    # @param [String] message a hash with hex format.
    # @return [BLS::PointG2] point.
    # @raise [BLS::PointError]
    def self.hash_to_curve(message)
      raise PointError, 'expected hex string' unless message[/^[a-fA-F0-9]*$/]

      u = BLS::H2C::G2.hash_to_field(message)
      q0 = PointG2.new(*BLS::H2C::G2.isogeny_map(*BLS::H2C::G2.map_to_curve_sswu(u[0])))
      q1 = PointG2.new(*BLS::H2C::G2.isogeny_map(*BLS::H2C::G2.map_to_curve_sswu(u[1])))
      r = q0 + q1
      clear_cofactor(r)
    end

    # Serialize pont as hex value.
    # @param [Boolean] compressed whether to compress the point.
    # @return [String] hex value of point.
    def to_hex(compressed: false)
      if compressed
        if zero?
          x1 = POW_2_383 + POW_2_382
          x0= 0
        else
          x, y = to_affine
          flag = if y.coeffs[1].value == 0
                   (y.coeffs[0].value * 2) / Curve::P
                 else
                   ((y.coeffs[1].value * 2) / Curve::P).zero? ? 0 : 1
                 end
          x1 = x.coeffs[1].value + flag * POW_2_381 + POW_2_383
          x0 = x.coeffs[0].value
        end
        BLS.num_to_hex(x1, PUBLIC_KEY_LENGTH) + BLS.num_to_hex(x0, PUBLIC_KEY_LENGTH)
      else
        if self == PointG2::ZERO
          (1 << 6).to_s(16) + '00' * (4 * PUBLIC_KEY_LENGTH - 1)
        else
          validate!
          x, y = to_affine.map(&:values)
          BLS.num_to_hex(x[1], PUBLIC_KEY_LENGTH) +
            BLS.num_to_hex(x[0], PUBLIC_KEY_LENGTH) +
            BLS.num_to_hex(y[1], PUBLIC_KEY_LENGTH) +
            BLS.num_to_hex(y[0], PUBLIC_KEY_LENGTH)
        end
      end
    end

    # Convert to signature with hex format.
    # @return [String] signature with hex format.
    # @deprecated Use {#to_hex} instead.
    def to_signature
      to_hex(compressed: true)
    end

    def validate!
      b = Fp2.new(Curve::B2)
      return if zero?

      left = y.pow(2) * z - x.pow(3)
      right = b * z.pow(3)
      raise PointError, 'Invalid point: not on curve over Fp2' unless left == right
    end

    def clear_pairing_precomputes
      self.precomputes = nil
    end

    def pairing_precomputes
      return precomputes if precomputes

      self.precomputes = calc_pairing_precomputes(*to_affine)
      precomputes
    end

    private

    def calc_pairing_precomputes(x, y)
      q_x, q_y, q_z = [x, y, Fp2::ONE]
      r_x, r_y, r_z = [q_x, q_y, q_z]
      ell_coeff = []
      i = BLS_X_LEN - 2
      while i >= 0
        t0 = r_y.square
        t1 = r_z.square
        t2 = t1.multiply(3).multiply_by_b
        t3 = t2 * 3
        t4 = (r_y + r_z).square - t1 - t0
        ell_coeff << [t2 - t0, r_x.square * 3, t4.negate]
        r_x = (t0 - t3) * r_x * r_y / 2
        r_y = ((t0 + t3) / 2).square - t2.square * 3
        r_z = t0 * t4
        unless BLS.bit_get(Curve::X, i).zero?
          t0 = r_y - q_y * r_z
          t1 = r_x - q_x * r_z
          ell_coeff << [t0 * q_x - t1 * q_y, t0.negate, t1]
          t2 = t1.square
          t3 = t2 * t1
          t4 = t2 * r_x
          t5 = t3 - t4 * 2 + t0.square * r_z
          r_x = t1 * t5
          r_y = (t4 - t5) * t0 - t3 * r_y
          r_z *= t3
        end
        i -= 1
      end
      ell_coeff
    end
    def self.clear_cofactor(p)
      t1 = p.multiply_unsafe(Curve::X).negate
      t2 = p.from_affine_tuple(BLS.psi(*p.to_affine))
      p2 = p.from_affine_tuple(BLS.psi2(*p.double.to_affine))
      p2 - t2 + (t1 + t2).multiply_unsafe(Curve::X).negate - t1 - p
    end
  end

end