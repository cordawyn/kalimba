require File.expand_path('../lib/kalimba/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Slava Kravchenko"]
  gem.email         = ["slava.kravchenko@gmail.com"]
  gem.description   = %q{ActiveModel-based framework, which allows the developer to combine RDF resources into ActiveRecord-like models.}
  gem.summary       = %q{Kalimba provides ActiveRecord-like capabilities for RDF resources.}
  gem.homepage      = "https://github.com/cordawyn/kalimba"

  ignore_files      = %w(Gemfile .gitignore kalimba.gemspec kalimba-redlander.gemspec lib/kalimba/persistence/redlander.rb)
  gem.files         = `git ls-files`.split($\) - ignore_files
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "kalimba"
  gem.require_paths = ["lib"]
  gem.version       = Kalimba::VERSION

  gem.license = "The MIT License (MIT)"

  gem.add_runtime_dependency "activemodel", "~> 3.2"
  gem.add_runtime_dependency "activesupport", "~> 3.2"

  gem.add_development_dependency "rspec", "~> 2.11.0"
  gem.add_development_dependency "kalimba-redlander"
end
