# frozen_string_literal: true

require 'bigdecimal'

module BLS

  class PointError < StandardError; end

  # Abstract Point class that consist of projective coordinates.
  class ProjectivePoint

    attr_reader :x, :y, :z
    attr_accessor :m_precomputes

    def initialize(x, y, z)
      @x = x
      @y = y
      @z = z
      @m_precomputes = nil
    end

    def zero?
      z.zero?
    end

    def zero
      one = x.class.const_get(:ONE)
      new_point(one, one, x.class.const_get(:ZERO))
    end

    def new_point(x, y, z)
      self.class.new(x, y, z)
    end

    # Compare one point to another.
    # @param [ProjectivePoint] other another point.
    # @return [Boolean] whether same point or not.
    def ==(other)
      raise PointError, "ProjectivePoint#==: this is #{self.class}, but other is #{other.class}" unless self.class == other.class

      (x * other.z) == (other.x * z) && (y * other.z) == (other.y * z)
    end

    def negate
      new_point(x, y.negate, z)
    end

    # http://hyperelliptic.org/EFD/g1p/auto-shortw-projective.html#doubling-dbl-1998-cmo-2
    def double
      w = x * x * 3
      s = y * z
      ss = s * s
      sss = ss * s
      b = x * y * s
      h = w * w - ( b * 8)
      x3 = h * s * 2
      y3 = w * (b * 4 - h) - (y * y * 8 * ss) # W * (4 * B - H) - 8 * y * y * S_squared
      z3 = sss * 8
      new_point(x3, y3, z3)
    end

    # http://hyperelliptic.org/EFD/g1p/auto-shortw-projective.html#addition-add-1998-cmo-2
    def add(other)
      raise PointError, "ProjectivePoint#add: this is #{self.class}, but other is #{other.class}" unless self.class == other.class

      return other if zero?
      return self if other.zero?

      x1 = self.x
      y1 = self.y
      z1 = self.z
      x2 = other.x
      y2 = other.y
      z2 = other.z
      u1 = y2 * z1
      u2 = y1 * z2
      v1 = x2 * z1
      v2 = x1 * z2
      return double if v1 == v2 && u1 == u2
      return zero if v1 == v2

      u = u1 - u2
      v = v1 - v2
      vv = v * v
      vvv = vv * v
      v2vv = v2 * vv
      w = z1 * z2
      a = u * u * w - vvv - v2vv * 2
      x3 = v * a
      y3 = u * (v2vv - a) - vvv * u2
      z3 = vvv * w
      new_point(x3, y3, z3)
    end
    alias + add

    def subtract(other)
      raise PointError, "ProjectivePoint#subtract: this is #{self.class}, but other is #{other.class}" unless self.class == other.class

      add(other.negate)
    end
    alias - subtract

    def multiply_unsafe(scalar)
      n = scalar.is_a?(Fq) ? scalar.value : scalar
      raise PointError, 'Point#multiply: invalid scalar, expected positive integer' if n <= 0

      p = zero
      d = self
      while n.positive?
        p += d unless (n & 1).zero?
        d = d.double
        n >>= 1
      end
      p
    end

    def to_affine(inv_z = z.invert)
      [x * inv_z, y * inv_z]
    end

    def to_affine_batch(points)
      to_inv = gen_invert_batch(points.map(&:z))
      points.map.with_index { |p, i| p.to_affine(to_inv[i]) }
    end

    def from_affine_tuple(xy)
      new_point(xy[0], xy[1], x.class.const_get(:ONE))
    end

    def gen_invert_batch(nums)
      len = nums.length
      scratch = Array.new(len)
      acc = x.class::ONE
      len.times do |i|
        next if nums[i].zero?

        scratch[i] = acc
        acc *= nums[i]
      end
      acc = acc.invert
      len.times do |t|
        i = len - t - 1
        next if nums[i].zero?

        tmp = acc * nums[i]
        nums[i] = acc * scratch[i]
        acc = tmp
      end
      nums
    end

    # Constant time multiplication. Uses wNAF.
    def multiply(scalar)
      n = scalar.is_a?(Fq) ? scalar.value : scalar
      raise PointError, 'Invalid scalar, expected positive integer' if n <= 0
      raise PointError, "Scalar has more bits than maxBits, shouldn't happen" if n.bit_length > max_bits

      wNAF(n).first
    end
    alias * multiply

    def precomputes_window(w)
      windows = (BigDecimal(max_bits) / w).ceil
      window_size = 2**(w - 1)
      points = []
      p = self
      windows.times do
        base = p
        points << base
        (1...window_size).each do
          base += p
          points << base
        end
        p = base.double
      end
      points
    end

    def max_bits
      self.class.const_get(:MAX_BITS)
    end

    def normalize_z(points)
      to_affine_batch(points).map{ |p| from_affine_tuple(p) }
    end

    def calc_multiply_precomputes(w)
      raise PointError, 'This point already has precomputes.' if m_precomputes

      self.m_precomputes = [w, normalize_z(precomputes_window(w))]
    end

    def clear_multiply_precomputes
      self.m_precomputes = nil
    end

    private

    def wNAF(n)
      w, precomputes = m_precomputes || [1, precomputes_window(1)]
      p = zero
      f = zero
      windows = (BigDecimal(max_bits) / w).ceil
      window_size = 2**(w - 1)
      mask = (2**w - 1)
      max_number = 2**w
      shift_by = w
      windows.times do |window|
        offset = window * window_size
        wbits = n & mask
        n >>= shift_by
        if wbits > window_size
          wbits -= max_number
          n += 1
        end
        if wbits.zero?
          f += (window % 2 ? precomputes[offset].negate : precomputes[offset])
        else
          cached = precomputes[offset + wbits.abs - 1]
          p += (wbits.negative? ? cached.negate : cached)
        end
      end
      [p, f]
    end
  end

  class PointG1 < ProjectivePoint

    BASE = PointG1.new(Fq.new(Curve::G_X), Fq.new(Curve::G_Y), Fq::ONE)
    ZERO = PointG1.new(Fq::ONE, Fq::ONE, Fq::ZERO)
    MAX_BITS = Fq::MAX_BITS

    # Parse PointG1 from form hex.
    # @param [String] hex hex value of PointG1.
    # @return [PointG1]
    # @raise [BLS::PointError] Occurs when hex length does not match, or point does not on G1.
    def self.from_hex(hex)
      bytes = [hex].pack('H*')
      point = case bytes.bytesize
              when 48
                compressed_value = hex.to_i(16)
                b_flag = BLS.mod(compressed_value, POW_2_383) / POW_2_382
                return ZERO if b_flag == 1

                x = BLS.mod(compressed_value, POW_2_381)
                full_y = BLS.mod(x**3 + Fq.new(Curve::B).value, Curve::P)
                y = BLS.pow_mod(full_y, (Curve::P + 1) / 4, Curve::P)
                raise PointError, 'The given point is not on G1: y**2 = x**3 + b.' unless (BLS.pow_mod(y, 2, Curve::P) - full_y).zero?

                a_flag = BLS.mod(compressed_value, POW_2_382) / POW_2_381
                y = Curve::P - y unless ((y * 2) / Curve::P) == a_flag
                PointG1.new(Fq.new(x), Fq.new(y), Fq::ONE)
              when 96
                return ZERO unless (bytes[0].unpack1('H*').to_i(16) & (1 << 6)).zero?

                x = bytes[0...PUBLIC_KEY_LENGTH].unpack1('H*').to_i(16)
                y = bytes[PUBLIC_KEY_LENGTH..-1].unpack1('H*').to_i(16)
                PointG1.new(Fq.new(x), Fq.new(y), Fq::ONE)
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

    # Validate this point whether on curve over Fq.
    # @raise [PointError] Occur when this point not on curve over Fq.
    def validate!
      b = Fq.new(Curve::B)
      return if zero?

      left = y.pow(2) * z - x.pow(3)
      right = b * z.pow(3)
      raise PointError, 'Invalid point: not on curve over Fq' unless left == right
    end

    # Sparse multiplication against precomputed coefficients.
    # @param [PointG2] p
    def miller_loop(p)
      BLS.miller_loop(p.pairing_precomputes, to_affine)
    end
  end

  class PointG2 < ProjectivePoint

    attr_accessor :precomputes

    MAX_BITS = Fq2::MAX_BITS
    BASE = PointG2.new(Fq2.new(Curve::G2_X), Fq2.new(Curve::G2_Y), Fq2::ONE)
    ZERO = PointG2.new(Fq2::ONE, Fq2::ONE, Fq2::ZERO)

    # Parse PointG1 from form hex.
    # @param [String] hex hex value of PointG2. Currently, only uncompressed formats(196 bytes) are supported.
    # @return [BLS::PointG2] PointG2 object.
    # @raise [BLS::PointError]
    def self.from_hex(hex)
      bytes = [hex].pack('H*')
      point = case bytes.bytesize
              when 96
                raise PointError, 'Compressed format not supported yet.'
              when 192
                return ZERO unless (bytes[0].unpack1('H*').to_i(16) & (1 << 6)).zero?

                x1 = bytes[0...PUBLIC_KEY_LENGTH].unpack1('H*').to_i(16)
                x0 = bytes[PUBLIC_KEY_LENGTH...(2 * PUBLIC_KEY_LENGTH)].unpack1('H*').to_i(16)
                y1 = bytes[(2 * PUBLIC_KEY_LENGTH)...(3 * PUBLIC_KEY_LENGTH)].unpack1('H*').to_i(16)
                y0 = bytes[(3 * PUBLIC_KEY_LENGTH)..-1].unpack1('H*').to_i(16)
                PointG2.new(Fq2.new([x0, x1]), Fq2.new([y0, y1]), Fq2::ONE)
              else
                raise PointError, 'Invalid uncompressed point G2, expected 192 bytes.'
              end
      point.validate!
      point
    end

    # Convert hash to PointG2
    # @param [String] message a hash with hex format.
    # @return [BLS::PointG2] point.
    # @raise [BLS::PointError]
    def self.hash_to_curve(message)
      raise PointError, 'expected hex string' unless message[/^[a-fA-F0-9]*$/]

      u = BLS.hash_to_field(message, 2)
      q0 = PointG2.new(*BLS.isogeny_map_g2(*BLS.map_to_curve_sswu_g2(u[0])))
      q1 = PointG2.new(*BLS.isogeny_map_g2(*BLS.map_to_curve_sswu_g2(u[1])))
      r = q0 + q1
      BLS.clear_cofactor_g2(r)
    end

    def to_hex(compressed: false)
      raise ArgumentError, 'Not supported' if compressed

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

    # Convert to signature with hex format.
    # @return [String] signature with hex format.
    def to_signature
      if self == PointG2::ZERO
        sum = POW_2_383 + POW_2_382
        return BLS.num_to_hex(sum, PUBLIC_KEY_LENGTH) + BLS.num_to_hex(0, PUBLIC_KEY_LENGTH)
      end
      validate!
      x, y = to_affine.map(&:values)
      tmp = y[1] > 0 ? y[1] * 2 : y[0] * 2
      aflag1 = tmp / Curve::P
      z1 = x[1] + aflag1 * POW_2_381 + POW_2_383
      z2 = x[0]
      BLS.num_to_hex(z1, PUBLIC_KEY_LENGTH) + BLS.num_to_hex(z2, PUBLIC_KEY_LENGTH)
    end

    def validate!
      b = Fq2.new(Curve::B2)
      return if zero?

      left = y.pow(2) * z - x.pow(3)
      right = b * z.pow(3)
      raise PointError, 'Invalid point: not on curve over Fq2' unless left == right
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
      q_x, q_y, q_z = [x, y, Fq2::ONE]
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
  end

  module_function

  def clear_cofactor_g2(p)
    t1 = p.multiply_unsafe(Curve::X).negate
    t2 = p.from_affine_tuple(BLS.psi(*p.to_affine))
    p2 = p.from_affine_tuple(BLS.psi2(*p.double.to_affine))
    p2 - t2 + (t1 + t2).multiply_unsafe(Curve::X).negate - t1 - p
  end

  def norm_p1(point)
    point.is_a?(PointG1) ? point : PointG1.from_hex(point)
  end

  def norm_p2(point)
    point.is_a?(PointG2) ? point : PointG2.from_hex(point)
  end

  def norm_p2h(point)
    point.is_a?(PointG2) ? point : PointG2.hash_to_curve(point)
  end

  # Convert hash to Field.
  # @param [String] message hash value with hex format.
  # @return [Array[Integer]] byte array.
  def hash_to_field(message, degree, random_oracle: true)
    count = random_oracle ? 2 : 1
    l = 64
    len_in_bytes = count * degree * l
    pseudo_random_bytes = BLS.expand_message_xmd(message, len_in_bytes)
    u = Array.new(count)
    count.times do |i|
      e = Array.new(degree)
      degree.times do |j|
        elm_offset = l * (j + i * degree)
        tv = pseudo_random_bytes[elm_offset...(elm_offset + l)]
        e[j] = BLS.mod(BLS.os2ip(tv), Curve::P)
      end
      u[i] = e
    end
    u
  end

  # @param [String] message hash value with hex format.
  # @param [Integer] len_in_bytes length
  # @return [Array[Integer]] byte array.
  # @raise BLS::Error
  def expand_message_xmd(message, len_in_bytes)
    b_in_bytes = BigDecimal(SHA256_DIGEST_SIZE)
    r_in_bytes = b_in_bytes * 2
    ell = (BigDecimal(len_in_bytes) / b_in_bytes).ceil
    raise BLS::Error, 'Invalid xmd length' if ell > 255

    dst_prime = DST_LABEL.bytes + BLS.i2osp(DST_LABEL.bytesize, 1)
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
end
