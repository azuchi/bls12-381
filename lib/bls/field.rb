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

end
