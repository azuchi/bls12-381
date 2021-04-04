# frozen_string_literal: true

require 'bls'

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

def create_fq2_items(amount)
  return BLS::Fq2.new([rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)]) if amount == 1

  amount.times.map do
    BLS::Fq2.new([rand(1..BLS::Fq::ORDER), rand(1..BLS::Fq::ORDER)])
  end
end

def create_fq12_items(amount)
  result = amount.times.map do
    items = 12.times.map { rand(1..BLS::Fq::ORDER) }
    BLS::Fq12.from_tuple(items)
  end
  result.size == 1 ? result.first : result
end

def create_point_g1_items(amount)
  result = amount.times.map do
    items = 3.times.map { rand(1..BLS::Fq::ORDER) }
    BLS::PointG1.new(items[0], items[1], items[2])
  end
  result.size == 1 ? result.first : result
end
