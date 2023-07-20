# frozen_string_literal: true

require_relative 'lib/bls/version'

Gem::Specification.new do |spec|
  spec.name          = 'bls12-381'
  spec.version       = BLS::VERSION
  spec.authors       = ['Shigeyuki Azuchi']
  spec.email         = ['azuchi@chaintope.com']

  spec.summary       = 'BLS12-381 implementation for Ruby.'
  spec.description   = 'BLS12-381 implementation for Ruby.'
  spec.homepage      = 'https://github.com/azuchi/bls12-381'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "h2c", "~> 0.2.0"

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '>= 12.3.3'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
