# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "rbs-depends_on_load_implicit_false"
  spec.version       = "1.0.0"
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = %q{Test Gem with dependency to rbs-load_implicit_false}
  spec.description   = %q{Test Gem with dependency to rbs-load_implicit_false}
  spec.homepage      = "https://example.com"
  spec.license       = 'MIT'

  spec.files         = [
    "lib/a.rb",
    "sig/a.rbs"
  ]

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rbs-load_implicit_false", "1.0.0"
  end
