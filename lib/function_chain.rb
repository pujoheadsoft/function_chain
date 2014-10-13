require "function_chain/version"
require "function_chain/pull_chain"
require "function_chain/relay_chain"

module FunctionChain
  module_function

  # Shortcut to
  # PullChain.new(receiver, *functions).call
  def pull(receiver, *functions)
    PullChain.new(receiver, *functions).call
  end
end
