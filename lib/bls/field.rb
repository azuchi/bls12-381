# frozen_string_literal: true

module BLS

  # Finite field
  module Field

    def self.mod(a, b)
      res = a % b
      res >= 0 ? res : b + res
    end

    def zero?
      value.zero?
    end

    def negate
      self.class.new(-value)
    end

    def ==(other)
      value == other.value
    end

    def invert
      x0 = 1
      x1 = 0
      y0 = 0
      y1 = 1
      a = self.class.const_get(:ORDER)
      b = value
      until a.zero?
        q, b, a = [b / a, a, b % a]
        x0, x1 = [x1, x0 - q * x1]
        y0, y1 = [y1, y0 - q * y1]
      end
      self.class.new(x0)
    end

    def add(other)
      self.class.new(value + other.value)
    end
    alias + add

    def square
      self.class.new(value**2)
    end

    def pow(n)
      v = value.pow(n, self.class.const_get(:ORDER))
      self.class.new(v)
    end
    alias ** pow

    def subtract(other)
      self.class.new(value - other.value)
    end
    alias - subtract

    def multiply(other)
      v = other.is_a?(Field) ? other.value : other
      self.class.new(value * v)
    end
    alias * multiply

    def div(other)
      v = other.is_a?(Field) ? other.invert : self.class.new(other).invert
      multiply(v)
    end
    alias / div
  end

  # Finite field over q.
  class Fq
    include Field

    ORDER = BLS::Curve::P

    attr_reader :value

    def initialize(value)
      raise ArgumentError, 'Invalid value.' unless value.is_a?(Integer)

      @value = Field.mod(value, ORDER)
    end

    ZERO = Fq.new(0)
    ONE = Fq.new(1)

  end

  # Finite field over r.
  class Fr
    include Field

    ORDER = BLS::Curve::R

    attr_reader :value

    def initialize(value)
      raise ArgumentError, 'Invalid value.' unless value.is_a?(Integer)

      @value = Field.mod(value, ORDER)
    end

    ZERO = Fr.new(0)
    ONE = Fr.new(1)

    def legendre
      pow((order - 1) / 2)
    end

  end

  # Module for a field over polynomial.
  # TT - ThisType, CT - ChildType, TTT - Tuple Type
  module FQP

    def ==(other)
      coeffs == other.coeffs
    end

    def add(other)
      self.class.new(coeffs.map.with_index { |v, i| v + other.coeffs[i] })
    end
    alias + add

    def subtract(other)
      self.class.new(coeffs.map.with_index { |v, i| v - other.coeffs[i] })
    end
    alias - subtract

    def div(other)
      inv = other.is_a?(Integer) ? Fq.new(other).invert.value : other.invert
      multiply(inv)
    end
    alias / div

    def negate
      self.class.new(coeffs.map(&:negate))
    end

    def pow(n)
      one = self.class.const_get(:ONE)
      return one if n.zero?
      return self if n == 1

      p = one
      d = self
      while n.positive?
        p *= d unless (n & 1).zero?
        n >>= 1
        d = d.square
      end
      p
    end
    alias ** pow
  end

  # Finite extension field over irreducible polynomial.
  # Fq(u) / (u^2 - β) where β = -1
  class Fq2
    include FQP

    # For Fq2 roots of unity.
    RV1 = 0x6af0e0437ff400b6831e36d6bd17ffe48395dabc2d3435e77f76e17009241c5ee67992f72ec05f4c81084fbede3cc09
    EV1 = 0x699be3b8c6870965e5bf892ad5d2cc7b0e85a117402dfd83b7f4a947e02d978498255a2aaec0ac627b5afbdf1bf1c90
    EV2 = 0x8157cd83046453f5dd0972b6e3949e4288020b5b8a9cc99ca07e27089a2ce2436d965026adad3ef7baba37f2183e9b5
    EV3 = 0xab1c2ffdd6c253ca155231eb3e71ba044fd562f6f72bc5bad5ec46a0b7a3b0247cf08ce6c6317f40edbc653a72dee17
    EV4 = 0xaa404866706722864480885d68ad0ccac1967c7544b447873cc37e0181271e006df72162a3d3e0287bf597fbf7f8fc1

    ORDER = BLS::Curve::P2
    COFACTOR = BLS::Curve::H2

    attr_reader :coeffs

    def initialize(coeffs)
      raise ArgumentError, 'Expected array with 2 elements' unless coeffs.size == 2

      @coeffs = coeffs.map { |c| c.is_a?(Integer) ? Fq.new(c) : c }
    end

    ROOT = Fq.new(-1)
    ZERO = Fq2.new([0, 0])
    ONE = Fq2.new([1, 0])

    # Eighth roots of unity, used for computing square roots in Fq2.
    ROOTS_OF_UNITY = [
      Fq2.new([1, 0]),
      Fq2.new([RV1, -RV1]),
      Fq2.new([0, 1]),
      Fq2.new([RV1, RV1]),
      Fq2.new([-1, 0]),
      Fq2.new([-RV1, RV1]),
      Fq2.new([0, -1]),
      Fq2.new([-RV1, -RV1])
    ].freeze

    # eta values, used for computing sqrt(g(X1(t)))
    ETAS = [
      Fq2.new([EV1, EV2]),
      Fq2.new([-EV2, EV1]),
      Fq2.new([EV3, EV4]),
      Fq2.new([-EV4, EV3])
    ].freeze

    FROBENIUS_COEFFICIENTS = [
      Fq.new(0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001),
      Fq.new(0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa)
    ].freeze

    def values
      coeffs.map(&:value)
    end

    def square
      c0 = coeffs[0]
      c1 = coeffs[1]
      a = c0 + c1
      b = c0 - c1
      c = c0 + c0
      Fq2.new([a * b, c * c1])
    end

    def multiply(other)
      return Fq2.new(coeffs.map { |c| c * other }) if other.is_a?(Integer)

      c0, c1 = coeffs
      r0, r1 = other.coeffs
      t1 = c0 * r0
      t2 = c1 * r1
      Fq2.new([t1 - t2, ((c0 + c1) * (r0 + r1)) - (t1 + t2)])
    end
    alias * multiply

    def invert
      a, b = values
      factor = Fq.new(a * a + b * b).invert
      Fq2.new([factor * a, factor * -b])
    end

    # Raises to q**i -th power
    def frobenius_map(power)
      Fq2.new([coeffs[0], coeffs[1] * FROBENIUS_COEFFICIENTS[power % 2]])
    end
  end

end
