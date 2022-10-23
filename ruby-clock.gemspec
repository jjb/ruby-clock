require_relative 'lib/ruby-clock/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-clock"
  spec.version       = RubyClock::VERSION
  spec.authors       = ["John Bachir"]
  spec.email         = ["j@jjb.cc"]

  spec.summary       = 'A job scheduler which runs jobs each in their own thread in a persistent process.'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.post_install_message = <<~MESSAGE

    If you are updating ruby-clock from 1→2, there are a few things you need to change in your Clockfile.

    It's quick, easy, and fun! See instructions here:
    https://github.com/jjb/ruby-clock/blob/main/CHANGELOG.md#migrating-from-ruby-clock-version-1-to-version-2

  MESSAGE

  spec.homepage      = "https://github.com/jjb/ruby-clock"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

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

  spec.add_dependency "rufus-scheduler", '~> 3.8'
  spec.add_dependency "method_source"
end
