module BLS
  module_function

  class PairingError < StandardError; end

  # @param [BLS::PointG1] p
  # @param [BLS::PointG2] q
  # @param [Boolean] with_final_exp
  # @return [BLS::Fq12]
  # @raise [BLS::PairingError] Occur when p.zero? or q.zero?
  # @raise [ArgumentError]
  def pairing(p, q, with_final_exp: true)
    raise ArgumentError, 'p should be BLS::PointG1 object' unless p.is_a?(BLS::PointG1)
    raise ArgumentError, 'q should be BLS::PointG2 object' unless p.is_a?(BLS::PointG2)
    raise PairingError, 'No pairings at point of Infinity' if p.zero? || q.zero?

    p.validate!
    q.validate!
    looped = p.miller_loop(q)
    with_final_exp ? looped.final_exponentiate : looped
  end

end
