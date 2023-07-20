# frozen_string_literal: true

require 'bls'
require 'securerandom'
require 'json'

NUM_RUNS = 10

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def create_fp2_items(amount)
  return BLS::Fp2.new([rand(1..BLS::Fp::ORDER), rand(1..BLS::Fp::ORDER)]) if amount == 1

  amount.times.map do
    BLS::Fp2.new([rand(1..BLS::Fp::ORDER), rand(1..BLS::Fp::ORDER)])
  end
end

def create_fp12_items(amount)
  result = amount.times.map do
    items = 12.times.map { rand(1..BLS::Fp::ORDER) }
    BLS::Fp12.from_tuple(items)
  end
  result.size == 1 ? result.first : result
end

def create_point_g1_items(amount)
  result = amount.times.map do
    items = 3.times.map { BLS::Fp.new(rand(1..BLS::Fp::ORDER)) }
    BLS::PointG1.new(items[0], items[1], items[2])
  end
  result.size == 1 ? result.first : result
end

def create_point_g2_items(amount)
  result = amount.times.map do
    items = create_fp2_items(3)
    BLS::PointG2.new(items[0], items[1], items[2])
  end
  result.size == 1 ? result.first : result
end

def fixture_file(relative_path)
  path = File.join(File.dirname(__FILE__), 'fixtures', relative_path)
  File.read(path)
end
