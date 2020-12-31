require_relative 'lib/ruby-clock/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-clock"
  spec.version       = RubyClock::VERSION
  spec.authors       = ["John Bachir"]
  spec.email         = ["j@jjb.cc"]

  spec.summary       = 'A "clock" process for invoking ruby code within a persistent runtime'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/jjb/ruby-clock"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jjb/ruby-clock"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.

  # todo: make this not depend on git? which wasted a lot of debugging time
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rufus-scheduler", '>= 3.7.0'
end
