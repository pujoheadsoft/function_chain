module FunctionChain
  # Base class of PullChain, RelayChain
  class BaseChain
    # Add functions to chain
    def add_all(*functions)
      insert_all(chain_elements.size, *functions)
      self
    end

    # Add function to chain
    def add(function)
      insert(chain_elements.size, function)
    end

    # Insert functions to chain
    def insert_all(index, *functions)
      functions.each_with_index { |f, i| insert(index + i, f) }
      self
    end

    # Insert function to chain
    def insert(index, function)
      if function.is_a? String
        do_insert_by_string(index, function)
      else
        do_insert(index, function)
      end
      self
    end

    # Delete from chain
    def delete_at(index)
      chain_elements.delete_at(index)
      self
    end

    # Clear function chain
    def clear
      chain_elements.clear
    end

    def to_s
      "#{self.class}#{chain_elements.map(&:to_s)}"
    end

    protected

    def do_insert(index, function)
      chain_element = create_chain_element(function)
      chain_elements.insert(index, chain_element)
      def_to_s(chain_element, function)
    end

    def do_insert_by_string(index, function)
      function.split(%r{(?<!\\)/}).reject(&:empty?).each_with_index do |f, i|
        splitted_function = f.gsub(%r{\\/}, "/")
        chain_element = create_chain_element(splitted_function)
        chain_elements.insert(index + i, chain_element)
        def_to_s(chain_element, splitted_function)
      end
    end

    def create_chain_element(function)
      case function
      when Symbol then create_chain_element_by_symbol(function)
      when Array then create_chain_element_by_array(function)
      when String then create_chain_element_by_string(function)
      else
        fail ArgumentError, <<-EOF.gsub(/^\s+|\n/, "")
        Not supported type #{function}(#{function.class}),
        supported type is #{supported_types}.
        EOF
      end
    end

    def def_to_s(target, value)
      target.singleton_class.class_eval do
        define_method :to_s do
          value
        end
      end
    end

    def validate_array_length(arr, expect_length, expect_format)
      unless expect_length == arr.length
        message = "Format Wrong #{arr}, expected format is [#{expect_format}]"
        fail ArgumentError, message
      end
    end

    def validate_element_type_of_array(arr, i, expect_types, types_as_string)
      unless target_is_a_one_of_types?(arr[i], expect_types)
        fail ArgumentError, "Format Wrong #{arr}," \
          " second element of array is must be #{types_as_string}"
      end
    end

    def target_is_a_one_of_types?(target, types)
      types.any? { |type| target.is_a? type }
    end

    def chain_elements
      @chain_elements ||= []
    end

    def supported_types
      [Symbol, Array, String]
    end
  end
end
