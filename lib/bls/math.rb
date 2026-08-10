# frozen_string_literal: true

module BLS

  module_function

  def mod(a, b)
    a % b
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
  # @return [Integer] Integer.
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

  # Normalize private key.
  # A key at or above the group order is reduced rather than rejected, matching the reference
  # implementation and the test vectors. Reducing raw entropy that way is slightly biased, so
  # prefer drawing the key from 0 < k < Fr::ORDER to begin with.
  # @param [String|Integer] private_key a private key with hex or number.
  # @return [BLS::Fr] Normalized private key.
  # @raise [BLS::Error] Occur when the private key is not a positive hex string or integer,
  # or when it reduces to zero.
  def normalize_priv_key(private_key)
    k = case private_key
        when String
          # String#to_i stops at the first character it cannot read and returns what it has,
          # so a mistyped or truncated key would otherwise turn into a different, much
          # smaller one without any sign that it happened.
          raise BLS::Error, 'Private key must be a hex string.' unless private_key.match?(/\A[0-9a-fA-F]+\z/)

          private_key.to_i(16)
        when Integer
          private_key
        else
          raise BLS::Error, 'Private key must be Integer or String.'
        end
    raise BLS::Error, 'Private key must be positive.' unless k.positive?

    key = Fr.new(k)
    raise BLS::Error, "Private key must not be a multiple of #{Fr::ORDER}." if key.zero?

    key
  end

  # Convert number to +byte_length+ bytes hex string.
  # @param [Integer] num number tobe converted.
  # @param [Integer] byte_length byte length.
  # @return [String] hex value.
  def num_to_hex(num, byte_length)
    num.to_s(16).rjust(2 * byte_length, '0')
  end

end
