# frozen_string_literal: true

require 'bigdecimal'
require 'h2c'

module BLS

  # Point serialization flags
  POINT_COMPRESSION_FLAG = 0x80
  POINT_INFINITY_FLAG = 0x40
  POINT_Y_FLAG = 0x20

  autoload :PointG1, "bls/point/g1"
  autoload :PointG2, "bls/point/g2"

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
      n = scalar.is_a?(Field) ? scalar.value : scalar
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
      n = scalar.is_a?(Field) ? scalar.value : scalar
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

  module_function

  def norm_p1(point)
    point.is_a?(PointG1) ? point : PointG1.from_hex(point)
  end

  def norm_p2(point)
    point.is_a?(PointG2) ? point : PointG2.from_hex(point)
  end

  def norm_p1h(point)
    point.is_a?(PointG1) ? point : PointG1.hash_to_curve(point)
  end

  def norm_p2h(point)
    point.is_a?(PointG2) ? point : PointG2.hash_to_curve(point)
  end

end
