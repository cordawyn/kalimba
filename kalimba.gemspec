# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kalimba/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["TODO: Write your name"]
  gem.email         = ["TODO: Write your email address"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "kalimba"
  gem.require_paths = ["lib"]
  gem.version       = Kalimba::VERSION

  gem.add_runtime_dependency "redlander", "~> 0.4.1"
  gem.add_runtime_dependency "activemodel", "~> 3.2"

  gem.add_development_dependency "rspec", "~> 2.11.0"
end
