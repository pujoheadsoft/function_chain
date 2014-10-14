require "function_chain/base_chain"

module FunctionChain
  # == PullChain
  # PullChain is object as represent method call chain.
  # Can inner object's method call of object.
  #
  # Chain is object, so can call later.
  #
  # Supported call chain type is like a
  #   account.user.name
  #
  # Unsupported call chain type is like a
  #   filter3(filter2(filter1(value)))
  # (RelayChain to support such type.)
  #
  # === Example
  #   Account = Struct.new(:user)
  #   User = Struct.new(:name)
  #   account = Account.new(User.new("Louis"))
  #
  #   chain = PullChain.new(account, :user, :name, :upcase)
  #   chain.call # => LOUIS
  #
  # similar.
  #   # Strings separated by a slash
  #   PullChain.new(account, "user/name/upcase").call
  #
  #   # use << operator.
  #   chain = PullChain.new(account)
  #   chain << :user << :name << :upcase
  #   chain.call
  #
  #   # use add method.
  #   chain.add(:user).add(:name).add(:upcase).call
  #
  #   # use add_all method.
  #   chain.add_all(:user, :name, :upcase).call
  #
  # can exist nil value on the way, like a following case.
  #   user.name = nil
  #   chain.call # => nil
  #
  # insert, insert_all method is insert_all method to chain.
  # delete_at method is delete method from chain.
  # clear method is delete all method from chain.
  #
  # === Require arguments on method
  # Following example is required two arguments.
  #   class Foo
  #     def say(speaker, message)
  #       puts "#{speaker} said '#{message}'"
  #     end
  #   end
  #
  # Solution1:Array, format is [Symbol, [*Args]].
  #   chain = PullChain.new(Foo.new) << [:say, ["Andres", "Hello"]]
  #   chain.call => Andres said 'Hello'
  #
  # Solution2:String
  #   chain = PullChain.new(foo) << "say('John', 'Goodbye')"
  #   chain.call => John said 'Goodbye'
  #
  # === Require block on method
  # [1,2,3,4,5].inject(3) { |sum, n| sum + n } # => 18
  #
  # Solution1:Array, format is [Symbol, [*Args, Proc]].
  #   chain = PullChain.new([1,2,3,4,5])
  #   chain << [:inject, [3, lambda { |sum, n| sum + n }]]
  #   chain.call # => 18
  #
  # Solution2:String
  #   chain = PullChain.new([1,2,3,4,5])
  #   chain << "inject(3) { |sum, n| sum + n }"
  #   chain.call # => 18
  #
  # === Use result on chain
  # Like a following example, can use result on chain.
  # Example1:String
  #   Foo = Struct.new(:bar)
  #   Bar = Struct.new(:baz) {
  #     def speaker ; "Julian" end
  #   }
  #   class Baz
  #     def say(speaker, message) puts "#{speaker} said '#{message}'" end
  #   end
  #   foo = Foo.new(Bar.new(Baz.new))
  #
  #   # can use bar instance in backward!
  #   chain = PullChain.new(foo) << "bar/baz/say(bar.speaker, 'Good!')"
  #   chain.call # => Julian said 'Good!'
  #
  # furthermore, can use variable name assigned.
  #   # @b is bar instance alias.
  #   chain = PullChain.new(foo) << "@b = bar/baz/say(b.speaker, 'Cool')"
  #   chain.call # => Julian said 'Cool'
  #
  # Example2:Array
  # can access result by Proc.
  #   chain = PullChain.new(foo) << :bar << :baz
  #   chain << [:say, Proc.new { next bar.speaker, "Oh" }]
  #   chain.call # => Julian said 'Oh'
  #
  # case of use a lambda, can use result access object explicit.
  #   chain = PullChain.new(foo) << :bar << :baz
  #   arg_reader = lambda { |accessor| next accessor.bar.speaker, "Oh" }
  #   chain << [:say, arg_reader]
  #   chain.call # => Julian said 'Oh'
  #
  # === etc
  # How to use slash in strings separated by a slash.
  # like following, please escaped by backslash.
  #   chain = PullChain.new("AC") << "concat '\\/DC'"
  #   chain.call # => AC/DC
  #
  # Use return_nil_at_error= method, then can ignore error.
  #   chain = PullChain.new("Test") << :xxx
  #   begin
  #     chain.call # => undefined method `xxx'
  #   rescue
  #   end
  #   chain.return_nil_at_error = true
  #   chain.call # => nil
  #
  # Note:use operator in string type chain
  #   table = {name: %w(Bill Scott Paul)}
  #   PullChain.new(table, "[:name]").call # NG
  #   PullChain.new(table, "self[:name]").call # OK
  #   # Array type chain
  #   PullChain.new(table, [:[], [:name]]).call # OK
  #
  # following is also the same.
  #   # <<operator of String
  #   PullChain.new("Led", "self << ' Zeppelin'").call
  #   # []operator of Array
  #   PullChain.new(%w(Donald Walter), "self[1]").call
  #
  # Some classes, such Fixnum and Bignum not supported.
  #   # NG
  #   PullChain.new(999999999999999, "self % 2").call
  #
  class PullChain < BaseChain
    attr_writer :return_nil_at_error

    # Initialize chain
    #
    # initialize(receiver, *functions)
    # receiver: starting point of method call.
    # *functions: more than one symbol, string, array.
    def initialize(receiver, *functions)
      @start_receiver = receiver
      @return_nil_at_error = false
      add_all(*functions)
    end

    # Call to all added method.
    def call
      @result_accessor = Object.new
      begin
        chain_elements.reduce(@start_receiver) do |receiver, chain_element|
          break receiver if receiver.nil?
          chain_element.call receiver
        end
      rescue
        raise unless return_nil_at_error?
      end
    end

    def return_nil_at_error?
      @return_nil_at_error
    end

    private

    attr_accessor :result_accessor

    def create_common_chain_element(&block)
      lambda do |receiver|
        name, result = block.call(receiver)
        define_result_access_method(name, result)
        result
      end
    end

    def define_result_access_method(name, result)
      result_accessor.singleton_class.class_eval do
        define_method name do
          result
        end
      end
    end

    def create_chain_element_by_symbol(symbol)
      create_common_chain_element do |receiver|
        next symbol, execute(receiver, symbol)
      end
    end

    def create_chain_element_by_array(array)
      validate_array_length(array, 2, "symbol, [*args] or Proc")
      validate_element_type_of_array(array, 1, [Array, Proc], "[*args] or Proc")

      do_create_chain_element_by_array(array[0], array[1])
    end

    def do_create_chain_element_by_array(name, array_function_param)
      create_common_chain_element do |receiver|
        args, block = extract_args_and_block(array_function_param)
        next name, execute(receiver, name, *args, &block)
      end
    end

    def extract_args_and_block(array_function_param)
      if array_function_param.is_a? Proc
        return result_accessor.instance_eval(&array_function_param)
      end
      if array_function_param.last.is_a? Proc
        return array_function_param[0...-1], array_function_param.last
      end
      array_function_param
    end

    def create_chain_element_by_string(string)
      name, function = split_to_name_and_function(string)
      create_common_chain_element do |receiver|
        next name, execute_by_string(receiver, function)
      end
    end

    def split_to_name_and_function(string)
      name = string
      function = string

      md = string.match(/^@.+?=/)
      if md
        name = md[0][1...-1].strip
        validate_variable_name_format(name)
        function = string.sub(md[0], "").strip
      end

      return name, function
    end

    def validate_variable_name_format(name)
      if name =~ /^[^a-zA-Z_]/
        fail ArgumentError, "wrong format variable defined #{name}"
      end
    end

    def execute(receiver, name, *args, &block)
      receiver.__send__(name, *args, &block)
    end

    def execute_by_string(receiver, function)
      begin
        inject_result_accessor(receiver)
        receiver.instance_eval(function)
      rescue => ex
        raise ex, "#{receiver}.#{function}"
      ensure
        eject_result_accessor(receiver)
      end
    end

    def inject_result_accessor(receiver)
      store_method_missing(receiver)
      define_intercepted_method_missing(receiver)
    end

    def store_method_missing(receiver)
      receiver.singleton_class.class_eval do
        alias_method :original_method_missing, :method_missing
      end
    end

    def define_intercepted_method_missing(receiver)
      # interception method_missing
      accessor = result_accessor
      receiver.singleton_class.class_eval do
        define_method :method_missing do |name, *args, &block|
          super(name, *args, &block) unless accessor.respond_to? name
          accessor.send(name, *args, &block)
        end
      end
    end

    def eject_result_accessor(receiver)
      # cleanup to interception
      receiver.singleton_class.class_eval do
        alias_method :method_missing, :original_method_missing
        undef_method :original_method_missing
      end
    end

    alias_method :<<, :add
  end
end
