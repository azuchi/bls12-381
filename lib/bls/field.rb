# frozen_string_literal: true

module BLS

  # Finite field
  module Field

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

      @value = BLS.mod(value, ORDER)
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

      @value = BLS.mod(value, ORDER)
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

    def mul_by_non_residue
      c0, c1 = coeffs
      t0 = c0 * 4
      t1 = c1 * 4
      Fq2.new([t0 - t1, t0 + t1])
    end
  end

  # Finite extension field over irreducible polynomial.
  # Fq2(v) / (v^3 - ξ) where ξ = u + 1
  class Fq6
    include FQP

    attr_reader :coeffs

    def initialize(coeffs)
      raise ArgumentError, 'Expected array with 3 elements' unless coeffs.size == 3

      @coeffs = coeffs
    end

    def self.from_tuple(t)
      Fq6.new([Fq2.new(t[0...2]), Fq2.new(t[2...4]), Fq2.new(t[4...6])])
    end

    ZERO = Fq6.new([Fq2::ZERO, Fq2::ZERO, Fq2::ZERO])
    ONE = Fq6.new([Fq2::ONE, Fq2::ZERO, Fq2::ZERO])

    FROBENIUS_COEFFICIENTS_1 = [
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac
              ]),
      Fq2.new([
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffefffe,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
              ]),
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
              ]),
      Fq2.new([
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffefffe
              ])
    ].freeze

    FROBENIUS_COEFFICIENTS_2 = [
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaad,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffefffe,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffeffff,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ])
    ].freeze

    # Multiply by quadratic non-residue v.
    def mul_by_non_residue
      Fq6.new([coeffs[2].mul_by_non_residue, coeffs[0], coeffs[1]])
    end

    def multiply(other)
      return Fq6.new([coeffs[0] * other, coeffs[1] * other, coeffs[2] * other]) if other.is_a?(Integer)

      c0, c1, c2 = coeffs
      r0, r1, r2 = other.coeffs
      t0 = c0 * r0
      t1 = c1 * r1
      t2 = c2 * r2

      Fq6.new([
                t0 + ((c1 + c2) * (r1 + r2) - (t1 + t2)).mul_by_non_residue,
                (c0 + c1) * (r0 + r1) - (t0 + t1) + t2.mul_by_non_residue,
                t1 + ((c0 + c2) * (r0 + r2) - (t0 + t2))
              ])
    end
    alias * multiply

    # Sparse multiplication.
    def multiply_by_1(b1)
      Fq6.new([coeffs[2].multiply(b1).mul_by_non_residue, coeffs[0] * b1, coeffs[1] * b1])
    end

    # Sparse multiplication.
    def multiply_by_01(b0, b1)
      c0, c1, c2 = coeffs
      t0 = c0 * b0
      t1 = c1 * b1
      Fq6.new([((c1 + c2) * b1 - t1).mul_by_non_residue + t0, (b0 + b1) * (c0 + c1) - t0 - t1, (c0 + c2) * b0 - t0 + t1])
    end

    def multiply_by_fq2(other)
      Fq6.new(coeffs.map { |c| c * other })
    end

    def square
      c0, c1, c2 = coeffs
      t0 = c0.square
      t1 = c0 * c1 * 2
      t3 = c1 * c2 * 2
      t4 = c2.square
      Fq6.new([t3.mul_by_non_residue + t0, t4.mul_by_non_residue + t1, t1 + (c0 - c1 + c2).square + t3 - t0 - t4])
    end

    def invert
      c0, c1, c2 = coeffs
      t0 = c0.square - (c2 * c1).mul_by_non_residue
      t1 = c2.square.mul_by_non_residue - (c0 * c1)
      t2 = c1.square - c0 * c2
      t4 = ((c2 * t1 + c1 * t2).mul_by_non_residue + c0 * t0).invert
      Fq6.new([t4 * t0, t4 * t1, t4 * t2])
    end

    def frobenius_map(power)
      Fq6.new([
                coeffs[0].frobenius_map,
                coeffs[1].frobenius_map * Fq6::FROBENIUS_COEFFICIENTS_1[power % 6],
                coeffs[2].frobenius_map * Fq6::FROBENIUS_COEFFICIENTS_2[power % 6]
              ])
    end
  end

  # Finite extension field over irreducible polynomial.
  # Fq6(w) / (w2 - γ) where γ = v
  class Fq12
    include FQP

    attr_reader :coeffs

    def initialize(coeffs)
      raise ArgumentError, 'Expected array with 2 elements' unless coeffs.size == 2

      @coeffs = coeffs
    end

    def self.from_tuple(t)
      Fq12.new([Fq6.from_tuple(t[0...6]), Fq6.from_tuple(t[6...12])])
    end

    ZERO = Fq12.new([Fq6::ZERO, Fq6::ZERO])
    ONE = Fq12.new([Fq6::ONE, Fq6::ZERO])

    FROBENIUS_COEFFICIENTS = [
      Fq2.new([
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x1904d3bf02bb0667c231beb4202c0d1f0fd603fd3cbd5f4f7b2443d784bab9c4f67ea53d63e7813d8d0775ed92235fb8,
                0x00fc3e2b36c4e03288e9e902231f9fb854a14787b6c7b36fec0c8ec971f63c5f282d5ac14d6c7ec22cf78a126ddc4af3
              ]),
      Fq2.new([
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffeffff,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x135203e60180a68ee2e9c448d77a2cd91c3dedd930b1cf60ef396489f61eb45e304466cf3e67fa0af1ee7b04121bdea2,
                0x06af0e0437ff400b6831e36d6bd17ffe48395dabc2d3435e77f76e17009241c5ee67992f72ec05f4c81084fbede3cc09
              ]),
      Fq2.new([
                0x00000000000000005f19672fdf76ce51ba69c6076a0f77eaddb3a93be6f89688de17d813620a00022e01fffffffefffe,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x144e4211384586c16bd3ad4afa99cc9170df3560e77982d0db45f3536814f0bd5871c1908bd478cd1ee605167ff82995,
                0x05b2cfd9013a5fd8df47fa6b48b1e045f39816240c0b8fee8beadf4d8e9c0566c63a3e6e257f87329b18fae980078116
              ]),
      Fq2.new([
                0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x00fc3e2b36c4e03288e9e902231f9fb854a14787b6c7b36fec0c8ec971f63c5f282d5ac14d6c7ec22cf78a126ddc4af3,
                0x1904d3bf02bb0667c231beb4202c0d1f0fd603fd3cbd5f4f7b2443d784bab9c4f67ea53d63e7813d8d0775ed92235fb8
              ]),
      Fq2.new([
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaac,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x06af0e0437ff400b6831e36d6bd17ffe48395dabc2d3435e77f76e17009241c5ee67992f72ec05f4c81084fbede3cc09,
                0x135203e60180a68ee2e9c448d77a2cd91c3dedd930b1cf60ef396489f61eb45e304466cf3e67fa0af1ee7b04121bdea2
              ]),
      Fq2.new([
                0x1a0111ea397fe699ec02408663d4de85aa0d857d89759ad4897d29650fb85f9b409427eb4f49fffd8bfd00000000aaad,
                0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
              ]),
      Fq2.new([
                0x05b2cfd9013a5fd8df47fa6b48b1e045f39816240c0b8fee8beadf4d8e9c0566c63a3e6e257f87329b18fae980078116,
                0x144e4211384586c16bd3ad4afa99cc9170df3560e77982d0db45f3536814f0bd5871c1908bd478cd1ee605167ff82995
              ])
    ].freeze

    def multiply(other)
      return Fq12.new([coeffs[0] * other, coeffs[1] * other]) if other.is_a?(Integer)

      c0, c1 = coeffs
      r0, r1 = other.coeffs
      t1 = c0 * r0
      t2 = c1 * r1
      Fq12.new([t1 + t2.mul_by_non_residue, (c0 + c1) * (r0 + r1) - (t1 + t2)])
    end
    alias * multiply

    def multiply_by_014(o0, o1, o4)
      c0, c1 = coeffs
      t0 = c0.multiply_by_01(o0, o1)
      t1 = c1.multiply_by_1(o4)
      Fq12.new([t1.mul_by_non_residue + t0, (c1 + c0).multiply_by_01(o0, o1 + o4) - t0 - t1])
    end

    def multiply_by_fq2(other)
      Fq12.new(coeffs.map{ |c| c.multiply_by_fq2(other) })
    end

    def square
      c0, c1 = coeffs
      ab = c0 * c1
      Fq12.new([(c1.mul_by_non_residue + c0) * (c0 + c1) - ab - ab.mul_by_non_residue, ab + ab])
    end

    def invert
      c0, c1 = coeffs
      t = (c0.square - c1.square.mul_by_non_residue).invert
      Fq12.new([c0 * t, (c1 * t).negate])
    end

    def frobenius_map(power)
      c0, c1 = coeffs
      r0 = c0.frobenius_map(power)
      c1_0, c1_1, c1_2 = c1.frobenius_map(power).coeffs
      Fq12.new([r0,
                Fq6.new([
                          c1_0 * Fq12::FROBENIUS_COEFFICIENTS[power % 12],
                          c1_1 * Fq12::FROBENIUS_COEFFICIENTS[power % 12],
                          c1_2 * Fq12::FROBENIUS_COEFFICIENTS[power % 12]
                        ])])
    end
  end
end
