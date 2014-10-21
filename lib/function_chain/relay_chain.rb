require "function_chain/base_chain"

module FunctionChain
  # == RelayChain
  # RelayChain is object like a connect to
  # function's input from function's output.
  # (methods well as can connect Proc.)
  #
  # Chain is object, so can call later.
  #
  # Supported call chain type is like a
  #   filter3(filter2(filter1(value))).
  #
  # Unsupported call chain type is like a
  #   account.user.name
  # (PullChain to support such type.)
  #
  # === Example
  #   class Decorator
  #     def decorate1(value)
  #       "( #{value} )"
  #     end
  #     def decorate2(value)
  #       "{ #{value} }"
  #     end
  #   end
  #   chain = RelayChain.new(Decorator.new, :decorate1, :decorate2)
  #   chain.call("Hello") # => { ( Hello ) }
  #
  # similar.
  #   # Strings separated by a slash
  #   chain = RelayChain.new(Decorator.new, "decorate1/decorate2")
  #   chain.call("Hello")
  #
  #   # use >> operator.
  #   chain = RelayChain.new(Decorator.new)
  #   chain >> :decorate1 >> :decorate2
  #   chain.call("Hello")
  #
  #   # use Method object
  #   chain = RelayChain.new
  #   chain >> decorator.method(:decorate1) >> decorator.method(:decorate2)
  #   chain.call("Hello")
  #
  #   # use add method
  #   chain.add(:decorate1).add(:decorate2).call("Hello")
  #
  #   # use add_all method
  #   chain.add_all(:decorate1, :decorate2).call("Hello")
  #
  # insert, insert_all method is insert function to chain.
  # delete_at method is delete function from chain.
  # clear method is delete all function from chain.
  #
  # === How to connect method of differed instance
  # Example, following two class.
  # Introduce how to connect method of these class.
  #   class Decorator
  #     def decorate1(value) "( #{value} )" end
  #     def decorate2(value) "{ #{value} }" end
  #   end
  #   class Decorator2
  #     def decorate(value) "[ #{value} ]" end
  #   end
  #
  # Solution1:Array, format is [instance, Symbol or String of method]
  #   chain = RelayChain.new(Decorator.new)
  #   chain >> :decorate1 >> :decorate2 >> [Decorator2.new, :decorate]
  #   # String ver.
  #   # chain >> :decorate1 >> :decorate2 >> [Decorator2.new, "decorate"]
  #   chain.call("Hello") # => [ { ( Hello ) } ]
  #
  # Solution2:String, use registered instance.
  #   chain = RelayChain.new(Decorator.new)
  #   # register name and instance
  #   chain.add_receiver("d2", Decorator2.new)
  #   # use registered instance
  #   chain >> "/decorate1/decorate2/d2.decorate"
  #   chain.call("Hello") # => [ { ( Hello ) } ]
  #
  #   # add_receiver_table method is register name and instance at once.
  #   chain.add_receiver_table({"x" => X.new, "y" => Y.new})
  #
  # === Case of method's output and method's input mismatch
  # Following example, decorate output is 1, and union input is 2.
  # How to do connect these methods?
  #   class Decorator
  #     def decorate(value)
  #       "#{value} And"
  #     end
  #     def union(value1, value2)
  #       "#{value1} #{value2}"
  #     end
  #   end
  #
  # Solution1:define connect method.
  #   class Decorator
  #     def connect(value)
  #       return value, "Palmer"
  #     end
  #   end
  #   chain = RelayChain.new(Decorator.new)
  #   chain >> :decorate >> :connect >> :union
  #   chain.call("Emerson, Lake") # => Emerson, Lake And Palmer
  #
  # Solution2:add lambda or Proc to between these methods.
  #   lambda's format is following.
  #     lambda {|chain, *args| chain.call(next function's arguments) }.
  #   lambda's parameter:chain is chain object.
  #   lambda's parameter:*args is previous function's output.
  #   can call next function by chain object.
  #
  #   chain = RelayChain.new(Decorator.new)
  #   arg_adder = lambda { |chain, value| chain.call(value, "Jerry") }
  #   chain >> :decorate >> arg_adder >> :union
  #   chain.call("Tom") # => Tom And Jerry
  #
  # === Appendix
  # Chain stop by means of lambda.
  #
  #   class Decorator
  #     def decorate1(value) "( #{value} )" end
  #     def decorate2(value) "{ #{value} }" end
  #   end
  #
  #   def create_stopper(&stop_condition)
  #     lambda do |chain, value|
  #       # if stop conditions are met then return value
  #       if stop_condition.call(value)
  #         value
  #       else
  #         chain.call(value)
  #       end
  #     end
  #   end
  #
  #   chain = RelayChain.new(Decorator.new, :decorate1, :decorate2)
  #
  #   # insert_all conditional chain stopper
  #   chain.insert(1, create_stopper { |value| value =~ /\d/ })
  #   chain.call("Van Halen 1984") # => ( Van Halen 1984 ) not enclosed to {}
  #   chain.call("Van Halen Jump") # => { ( Van Halen Jump ) } enclosed to {}
  #
  class RelayChain < BaseChain
    # Initialize chain
    #
    # initialize(common_receiver = nil, *functions)
    # common_receiver:used if the instance is omitted
    # *functions: more than one symbol, string, array, method, proc
    def initialize(common_receiver = nil, *functions)
      @common_receiver = common_receiver
      @index = 0
      add_all(*functions)
    end

    # Call to all added function.
    def call(*args)
      begin
        return if last?
        chain_element = chain_elements[@index]
        @index += 1
        chain_element.call(self, *args)
      ensure
        @index = 0
      end
    end

    # Whether chain last
    def last?
      @index == chain_elements.length
    end

    # add receiver
    # use by string type function.
    #
    # add_receiver(name, receiver)
    # name:receiver's name
    # receiver:register this receiver
    def add_receiver(name, receiver)
      receiver_table[name] = receiver
      self
    end

    # register name and instance at once.
    #
    # add_receiver_table(table)
    # table:hash {receiver's name as String => receiver, ...}
    def add_receiver_table(table)
      receiver_table.merge! table
      self
    end

    protected

    def supported_types
      super() | [Method]
    end

    private

    def create_chain_element(function)
      case function
      when Method then create_chain_element_by_method(function)
      else super(function)
      end
    end

    def create_common_chain_element(&block)
      lambda do |chain, *args|
        chain.last? ? block.call(*args) : chain.call(*block.call(*args))
      end
    end

    def create_chain_element_by_method(method)
      create_common_chain_element { |*args| method.call(*args) }
    end

    def create_chain_element_by_array(arr)
      validate_array_length(arr, 2, "receiver, symbol or string of receiver's method name")
      validate_element_type_of_array(arr, 1, [Symbol, String], "[Symbol or String]")

      create_common_chain_element { |*args| arr[0].__send__(arr[1], *args) }
    end

    def create_chain_element_by_symbol(symbol)
      create_common_chain_element do |*args|
        @common_receiver.__send__(symbol, *args)
      end
    end

    def create_chain_element_by_string(string)
      create_common_chain_element do |*args|
        index = string.index(".")
        if index
          receiver_key = string[0...index]
          receiver_method = string[index + 1..-1]
          receiver_table[receiver_key].send(receiver_method, *args)
        else
          @common_receiver.__send__(string, *args)
        end
      end
    end

    def create_chain_element_by_proc(proc)
      proc
    end

    def receiver_table
      @receiver_table ||= {}
    end

    alias_method :>>, :add
  end
end
