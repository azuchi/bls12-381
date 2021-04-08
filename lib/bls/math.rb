# frozen_string_literal: true

module BLS

  module_function

  def mod(a, b)
    res = a % b
    res >= 0 ? res : b + res
  end

  def pow_mod(a, power, m)
    res = 1
    while power.positive?
      res = mod(res * a, m) unless (power & 1).zero?
      power >>= 1
      a = mod(a * a, m)
    end
    res
  end

  def bit_get(n, pos)
    (n >> pos) & 1
  end

  # Convert byte to non-negative integer.
  # @param [Array[Integer]] bytes byte array.
  # @return [Array[Integer]] byte array.
  def os2ip(bytes)
    res = 0
    bytes.each do |b|
      res <<= 8
      res += b
    end
    res
  end

  # Convert +value+ to byte array of +length+.
  # @param [Integer] value
  # @param [Integer] length
  # @return [Array[Integer] byte array.
  # @raise [BLS::Error]
  def i2osp(value, length)
    raise BLS::Error, "bad I2OSP call: value=#{value} length=#{length}" if value < 0 || value >= (1 << 8 * length)

    res = Array.new(length, 0)
    i = length - 1
    while i >= 0
      res[i] = value & 0xff
      value >>= 8
      i -= 1
    end
    res
  end

  # Calculate binary xor between +a+ and +b+.
  # @param [String] a binary string.
  # @param [String] b binary string.
  # @return [String] xor binary string.
  def bin_xor(a, b)
    res = Array.new(a.bytesize)
    b_bytes = b.bytes
    a.bytes.each.with_index do |b, i|
      res[i] = b ^ b_bytes[i]
    end
    res.pack('C*')
  end

  # Optimized SWU Map - FQ2 to G2': y^2 = x^3 + 240i * x + 1012 + 1012i
  def map_to_curve_sswu_g2(t)
    iso_3_a = Fq2.new([0, 240])
    iso_3_b = Fq2.new([1012, 1012])
    iso_3_z = Fq2.new([-2, -1])
    t = Fq2.new(t) if t.is_a?(Array)
    t2 = t**2
    iso_3_z_t2 = iso_3_z * t2
    ztzt = iso_3_z_t2 + iso_3_z_t2**2
    denominator = (iso_3_a * ztzt).negate
    numerator = iso_3_b * (ztzt + Fq2::ONE)
    denominator = iso_3_z * iso_3_a if denominator.zero?
    v = denominator**3
    u = numerator**3 + iso_3_a * numerator * denominator**2 + iso_3_b * v
    success, sqrt_candidate_or_gamma = BLS.sqrt_div_fq2(u, v)
    y = success ? sqrt_candidate_or_gamma : nil
    sqrt_candidate_x1 = sqrt_candidate_or_gamma * t**3
    u = iso_3_z_t2**3 * u
    success2 = false
    Fq2::ETAS.each do |eta|
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
  def isogeny_map_g2(x, y, z)
    mapped = Array.new(4, Fq2::ZERO)
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

  # Normalize private key.
  # @param [String|Integer] private_key a private key with hex or number.
  # @return [BLS::Fq] private key field.
  # @raise [BLS::Error] Occur when the private key is zero.
  def normalize_priv_key(private_key)
    k = private_key.is_a?(String) ? private_key.to_i(16) : private_key
    fq = Fq.new(k)
    raise BLS::Error, 'Private key cannot be 0' if fq.zero?

    fq
  end

  # Convert number to +byte_length+ bytes hex string.
  # @param [Integer] num number tobe converted.
  # @param [Integer] byte_length byte length.
  # @return [String] hex value.
  def num_to_hex(num, byte_length)
    num.to_s(16).rjust(2 * byte_length, '0')
  end

end
