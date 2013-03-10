require File.expand_path('../lib/kalimba/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "kalimba-redlander"
  gem.version       = Kalimba::VERSION
  gem.authors       = ["Slava Kravchenko"]
  gem.email         = ["slava.kravchenko@gmail.com"]
  gem.description   = %q{Redlander adapter for Kalimba. It provides the RDF storage backend for Kalimba.}
  gem.summary       = %q{Redlander adapter for Kalimba}
  gem.homepage      = "https://github.com/cordawyn/kalimba-redlander"

  gem.files         = ["lib/kalimba/persistence/redlander.rb"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "kalimba"
  gem.add_runtime_dependency "redlander", "~> 0.6.0"
end
