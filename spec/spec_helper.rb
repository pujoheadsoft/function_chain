require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter ".bundle/"
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "function_chain"
