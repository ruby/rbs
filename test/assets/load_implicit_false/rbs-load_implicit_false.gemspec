# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "rbs-load_implicit_false"
  spec.version       = "1.0.0"
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = %q{Test Gem with load_implicitly=false}
  spec.description   = %q{Test Gem with load_implicitly=false}
  spec.homepage      = "https://example.com"
  spec.license       = 'MIT'

  spec.files         = [
    "lib/a.rb",
    "sig/a.rbs"
  ]
  spec.require_paths = ["lib"]
end
