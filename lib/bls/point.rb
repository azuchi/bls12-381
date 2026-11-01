# frozen_string_literal: true

require 'h2c'

module BLS

  # Point serialization flags
  POINT_COMPRESSION_FLAG = 0x80
  POINT_INFINITY_FLAG = 0x40
  POINT_Y_FLAG = 0x20

  autoload :PointG1, "bls/point/g1"
  autoload :PointG2, "bls/point/g2"

  # Abstract Point class that consist of projective coordinates.
  class ProjectivePoint

    # Bits in the group order r. Every point this library hands out lies in the subgroup of
    # that order, where [n]P == [n mod r]P, so this, not the size of the base field, is what
    # a scalar multiplication has to cover.
    SCALAR_BITS = Curve::R.bit_length

    attr_reader :x, :y, :z
    attr_accessor :m_precomputes

    def initialize(x, y, z)
      @x = x
      @y = y
      @z = z
      @m_precomputes = nil
    end

    # Domain separation tag this point class uses for +scheme+.
    # @param [Symbol] scheme :basic, :pop, or :pop_proof(the tag proofs of possession
    # are signed under, kept separate from :pop so a proof cannot pass as a signature).
    # @return [String] domain separation tag.
    # @raise [BLS::Error] Occur when the scheme is unknown.
    def self.dst(scheme)
      case scheme
      when :basic then const_get(:DST_BASIC)
      when :pop then const_get(:DST_POP)
      when :pop_proof then const_get(:DST_POP_PROOF)
      else raise BLS::Error, "Unknown scheme: #{scheme.inspect}. Must be :basic or :pop."
      end
    end

    # Check that +hex+ is a whole number of bytes written in hex, for {from_hex} and
    # {hash_to_curve}, which both unpack their argument with pack('H*').
    #
    # pack maps a character to a nibble by its low bits, so it reads '3', '#', 'J', 'Z', 'j'
    # and 'z' all as 3 and never complains, and it pads an odd number of digits out to a whole
    # byte. Left alone, that gives every point and every message a large family of spellings
    # that all arrive at the same bytes. Applications tend to carry keys around as hex and
    # compare, deduplicate and index them that way, so the aliases matter as much here as the
    # non-canonical encodings do a layer down.
    #
    # \A..\z rather than ^..$ because those match at line boundaries in Ruby, which would let
    # a newline carry a non-hex tail past the check.
    # @param [String] hex a byte string in hex format.
    # @raise [PointError] Occur when it is not an even length string of hex digits.
    def self.validate_hex!(hex)
      return if hex.is_a?(String) && hex.match?(/\A(?:[0-9a-fA-F]{2})*\z/)

      raise PointError, 'expected hex string'
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

    # Scalar multiplication by plain double-and-add, which skips the addition entirely on a
    # zero bit and so takes a number of operations that tracks the scalar's Hamming weight.
    # Only for scalars an observer already knows, such as the curve parameters. {multiply}
    # hides that particular pattern, but is not constant time either.
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

    # Check whether this point belongs to the prime-order subgroup (G1 or G2).
    # Being on the curve is not sufficient: E(Fp) and E'(Fp2) both contain points
    # outside the order-r subgroup, and accepting them makes keys and signatures malleable.
    # Since r**2 does not divide the group order, [r]P == O holds only for P in the subgroup.
    # That is the definition and the reference the specs compare against; PointG1 and PointG2
    # override it with an endomorphism check that reaches the same answer in a fraction of
    # the time.
    # @return [Boolean] true if this point is in the prime-order subgroup.
    def in_group?
      zero? || multiply_unsafe(Curve::R).zero?
    end

    # Validate that this point belongs to the prime-order subgroup.
    # @raise [PointError] Occur when this point is not in the prime-order subgroup.
    def validate_group!
      raise PointError, 'Invalid point: not in prime-order subgroup' unless in_group?
    end

    def to_affine(inv_z = z.invert)
      [x * inv_z, y * inv_z]
    end

    # @raise [PointError] Occur when any of +points+ is the point at infinity, which has no
    # affine representation.
    def to_affine_batch(points)
      raise PointError, 'The point at infinity has no affine representation.' if points.any?(&:zero?)

      to_inv = gen_invert_batch(points.map(&:z))
      points.map.with_index { |p, i| p.to_affine(to_inv[i]) }
    end

    def from_affine_tuple(xy)
      new_point(xy[0], xy[1], x.class.const_get(:ONE))
    end

    # Inverts a whole array for the price of one inversion plus a few multiplications each.
    # Zero is refused rather than skipped: leaving it in place would hand the caller a zero
    # where it asked for an inverse, and Field#invert refuses it for the same reason.
    # @raise [BLS::Error] Occur when any element is zero.
    def gen_invert_batch(nums)
      raise BLS::Error, 'Zero has no multiplicative inverse.' if nums.any?(&:zero?)

      len = nums.length
      scratch = Array.new(len)
      acc = x.class::ONE
      len.times do |i|
        scratch[i] = acc
        acc *= nums[i]
      end
      acc = acc.invert
      len.times do |t|
        i = len - t - 1
        tmp = acc * nums[i]
        nums[i] = acc * scratch[i]
        acc = tmp
      end
      nums
    end

    # Scalar multiplication using wNAF.
    #
    # This is NOT constant time, despite what {multiply_unsafe} implies by contrast. The
    # number of additions follows the number of non-zero windows in the scalar, the point
    # each one adds is read at an index derived from the scalar, and the additions themselves
    # branch on whether an operand is the identity or the two are equal. Underneath, Ruby's
    # bignum arithmetic and the modulo in Fp both run in time that depends on their operands.
    # Anything the scalar decides is therefore visible to something watching timing or cache
    # behaviour, which matters here because #sign and .from_private_key reach this with the
    # private key. See the README.
    #
    # noble, which this follows, adds a throwaway point on every zero window so that each
    # window costs one addition whatever its digit. That buys nothing here, where the
    # arithmetic underneath is not constant time to begin with, so the zero windows are
    # skipped and the work saved instead.
    def multiply(scalar)
      n = scalar.is_a?(Field) ? scalar.value : scalar
      raise PointError, 'Invalid scalar, expected positive integer' if n <= 0

      # Reduced modulo r so that wNAF has {SCALAR_BITS} bits to walk, whatever was passed in.
      # The table used to be sized from the base field instead, 381 bits for G1 and 762 for
      # G2, and every window past the scalar's top bit was a wasted addition.
      n %= Curve::R
      return zero if n.zero?

      wNAF(n)
    end
    alias * multiply

    def precomputes_window(w)
      windows = window_count(w)
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

    # Number of width-+w+ windows that {wNAF} walks and {precomputes_window} must cover.
    #
    # One bit more than the scalar has. A window whose digit comes out above 2**(w - 1) is
    # recoded as a negative digit and carries 1 into the next window, and when the top
    # window of the scalar does that, the carry needs a window of its own or it is dropped
    # on the floor. With r's top five bits being 11100, a width of 5 hits this for about
    # four scalars in ten.
    # @param [Integer] w window width.
    # @return [Integer] window count.
    def window_count(w)
      (SCALAR_BITS + w) / w
    end

    def normalize_z(points)
      to_affine_batch(points).map{ |p| from_affine_tuple(p) }
    end

    # Build the window table that {multiply} then uses, trading memory for speed on a point
    # that will be multiplied repeatedly, such as a generator.
    #
    # Call this once, before the point is shared between threads. The check below is not a
    # lock: the table takes long enough to build that MRI will switch threads part way
    # through, so several callers can pass the check together and each build their own, each
    # paying the time and the memory. What they build is identical, so whichever assignment
    # lands last is still correct and no half-built table is ever visible; the cost is the
    # duplicated work, and a guard that reads as protection while providing none.
    #
    # @param [Integer] w window width.
    # @raise [PointError] Occur when this point already has precomputes.
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
      windows = window_count(w)
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
        next if wbits.zero?

        cached = precomputes[offset + wbits.abs - 1]
        p += (wbits.negative? ? cached.negate : cached)
      end
      p
    end
  end

  module_function

  def norm_p1h(point, scheme: :basic)
    point.is_a?(PointG1) ? point : PointG1.hash_to_curve(point, scheme: scheme)
  end

  def norm_p2h(point, scheme: :basic)
    point.is_a?(PointG2) ? point : PointG2.hash_to_curve(point, scheme: scheme)
  end

end
