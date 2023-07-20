module BLS
  module H2C

    LENGTH = 64

    module_function

    # @param [String] message hash value with hex format.
    # @param [Integer] len_in_bytes length
    # @return [Array[Integer]] byte array.
    # @raise BLS::Error
    def expand_message_xmd(message, len_in_bytes)
      b_in_bytes = BigDecimal(SHA256_DIGEST_SIZE)
      r_in_bytes = b_in_bytes * 2
      ell = (BigDecimal(len_in_bytes) / b_in_bytes).ceil
      raise BLS::Error, 'Invalid xmd length' if ell > 255

      dst_prime = PointG2::DST_BASIC.bytes + BLS.i2osp(PointG2::DST_BASIC.bytesize, 1)
      z_pad = BLS.i2osp(0, r_in_bytes)
      l_i_b_str = BLS.i2osp(len_in_bytes, 2)
      b = Array.new(ell)
      payload = z_pad + [message].pack('H*').bytes + l_i_b_str + BLS.i2osp(0, 1) + dst_prime
      b_0 = Digest::SHA256.digest(payload.pack('C*'))
      b[0] = Digest::SHA256.digest((b_0.bytes + BLS.i2osp(1, 1) + dst_prime).pack('C*'))
      (1..ell).each do |i|
        args = BLS.bin_xor(b_0, b[i - 1]).bytes + BLS.i2osp(i + 1, 1) + dst_prime
        b[i] = Digest::SHA256.digest(args.pack('C*'))
      end
      b.map(&:bytes).flatten[0...len_in_bytes]
    end

    module G2
      module_function

      # Convert hash to Field.
      # @param [String] message hash value with hex format.
      # @return [Array[Integer]] byte array.
      def hash_to_field(message, random_oracle: true)
        degree = 2
        count = random_oracle ? 2 : 1
        len_in_bytes = count * degree * LENGTH
        pseudo_random_bytes = BLS::H2C.expand_message_xmd(message, len_in_bytes)
        u = Array.new(count)
        count.times do |i|
          e = Array.new(degree)
          degree.times do |j|
            elm_offset = LENGTH * (j + i * degree)
            tv = pseudo_random_bytes[elm_offset...(elm_offset + LENGTH)]
            e[j] = BLS.mod(BLS.os2ip(tv), Curve::P)
          end
          u[i] = e
        end
        u
      end

      # Optimized SWU Map - Fp2 to G2': y^2 = x^3 + 240i * x + 1012 + 1012i
      def map_to_curve_sswu(t)
        iso_3_a = Fp2.new([0, 240])
        iso_3_b = Fp2.new([1012, 1012])
        iso_3_z = Fp2.new([-2, -1])
        t = Fp2.new(t) if t.is_a?(Array)
        t2 = t**2
        iso_3_z_t2 = iso_3_z * t2
        ztzt = iso_3_z_t2 + iso_3_z_t2**2
        denominator = (iso_3_a * ztzt).negate
        numerator = iso_3_b * (ztzt + Fp2::ONE)
        denominator = iso_3_z * iso_3_a if denominator.zero?
        v = denominator**3
        u = numerator**3 + iso_3_a * numerator * denominator**2 + iso_3_b * v
        success, sqrt_candidate_or_gamma = BLS.sqrt_div_fp2(u, v)
        y = success ? sqrt_candidate_or_gamma : nil
        sqrt_candidate_x1 = sqrt_candidate_or_gamma * t**3
        u = iso_3_z_t2**3 * u
        success2 = false
        Fp2::ETAS.each do |eta|
          eta_sqrt_candidate = eta * sqrt_candidate_x1
          temp = eta_sqrt_candidate**2 * v - u
          if temp.zero? && !success && !success2
            y = eta_sqrt_candidate
            success2 = true
          end
        end
        raise BLS::PointError, 'Hash to Curve - Optimized SWU failure' if !success && !success2

        numerator *= iso_3_z_t2 if success2
        y = y.negate if BLS.sgn0(t) != BLS.sgn0(y)
        y *= denominator
        [numerator, y, denominator]
      end

      # 3-isogeny map from E' to E
      # Converts from Jacobi (xyz) to Projective (xyz) coordinates.
      def isogeny_map(x, y, z)
        mapped = Array.new(4, Fp2::ZERO)
        z_powers = [z, z**2, z**3]
        ISOGENY_COEFFICIENTS.each.with_index do |k, i|
          mapped[i] = k[-1]
          arr = k[0...-1].reverse
          arr.each.with_index do |a, j|
            mapped[i] = mapped[i] * x + z_powers[j] * a
          end
        end
        mapped[2] *= y
        mapped[3] *= z
        z2 = mapped[1] * mapped[3]
        x2 = mapped[0] * mapped[3]
        y2 = mapped[1] * mapped[2]
        [x2, y2, z2]
      end

    end

  end
end