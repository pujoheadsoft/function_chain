# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "function_chain/version"

Gem::Specification.new do |spec|
  spec.name          = "function_chain"
  spec.version       = FunctionChain::VERSION
  spec.authors       = ["Kenji Suzuki"]
  spec.email         = ["pujoheadsoft@gmail.com"]
  spec.summary       = "FunctionChain objectifies of the method chain."
  spec.description   = <<-EOF.gsub(/^\s+|\n/, "")
    FunctionChain objectifies of the method chain.
    chain objects can call later or add chain or insert_all chain or delete chain.
    supported chain type is following: foo.bar.baz, baz(bar(foo(value))).
  EOF
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"
  spec.required_rubygems_version = ">= 1.3.5"
  spec.add_development_dependency "bundler", "~> 1.7"
end
