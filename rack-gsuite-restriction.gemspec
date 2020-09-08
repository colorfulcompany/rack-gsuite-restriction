lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/gsuite_restriction/version"

Gem::Specification.new do |spec|
  spec.name          = "rack-gsuite_restriction"
  spec.version       = Rack::GSuiteRestriction::VERSION
  spec.authors       = ["T.Watanabe"]
  spec.email         = ["watanabe@colorfulcompany.co.jp"]

  spec.summary       = %q{Write a short summary, because RubyGems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/colorfulcompany/rack-gsuite-restriction"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/colorfulcompany/rack-gsuite-restriction"
  spec.metadata["changelog_uri"] = "https://github.com/colorfulcompany/rack-gsuite-restriction"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "rack-contrib"
  spec.add_dependency "omniauth-google-oauth2"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "yard", "~> 0"
  spec.add_development_dependency "minitest-power_assert", "~> 0"
  spec.add_development_dependency "minitest-reporters", "~> 1"
  spec.add_development_dependency "rack-test", "~> 1"
  spec.add_development_dependency "pry-byebug", "~> 3"
  spec.add_development_dependency "hashie", "~> 4"
end
