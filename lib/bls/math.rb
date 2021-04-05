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

  # Normalize private key.
  # @param [String|Integer] private_key a private key with hex or number.
  # @return [BLS::Fq] private key field.
  # @raise [BLS::Error] Occur when the private key is zero.
  def normalize_priv_key(private_key)
    k = private_key.is_a?(String) ? private_key.to_i(16) : private_key
    fq = Fq.new(k)
    raise BLS::Error, 'Private key cannot be 0'
    fq
  end

end
