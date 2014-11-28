# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'navy/version'

Gem::Specification.new do |spec|
  spec.name          = "navyrb"
  spec.version       = Navy::VERSION
  spec.authors       = ["Navy Project"]
  spec.email         = ["mail@navyproject.com"]
  spec.summary       = %q{Navy library for ruby}
  spec.description   = %q{Provides utilities for navy project}
  spec.homepage      = ""
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "webmock"
end
