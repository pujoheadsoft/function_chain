# FunctionChain

[![Build Status](http://img.shields.io/travis/pujoheadsoft/function_chain.svg)][travis]
[![Coverage Status](http://img.shields.io/coveralls/pujoheadsoft/function_chain.svg)][coveralls]
[![Code Climate](http://img.shields.io/codeclimate/github/pujoheadsoft/function_chain.svg)][codeclimate]

[travis]: http://travis-ci.org/pujoheadsoft/function_chain
[coveralls]: https://coveralls.io/r/pujoheadsoft/function_chain
[codeclimate]: https://codeclimate.com/github/pujoheadsoft/function_chain

## Description
**FunctionChain** objectifies of the method chain.  
Chain object can following.
* Call later.
* Add method to chain
* Insert method to chain.
* Delete method from chain.

## Installation
    gem install function_chain

## PullChain & RelayChain
**PullChain & RelayChain** is FunctionChain module's classes.  
PullChain & RelayChain will support call chain type, each different.

* PullChain to support the type such as the following:
  ```ruby
  account.user.name
  ```
  If used the PullChain (detail description is [here](#pullchain))
  ```ruby
  chain = PullChain.new(account) << :user << :name
  chain.call
```

* RelayChain to support the type such as the following:
  ```ruby
  filter3(filter2(filter1(value)))
  ```
  If used the RelayChain (detail description is [here](#relaychain))
  ```ruby
  chain = RelayChain.new >> :filter1 >> :filter2 >> :filter3
  chain.call("XXX")
  ```


## Usage and documentation
The following is necessary call to use the PullChain or RelayChain.
```ruby
require "function_chain"
include FunctionChain
```
**Note:** This document omit the above code from now on.
## PullChain
PullChain is object as represent method call chain.  
Can inner object's method call of object.
### Example
```ruby
Account = Struct.new(:user)
User = Struct.new(:name)
account = Account.new(User.new("Louis"))

chain = PullChain.new(account, :user, :name, :upcase)
chain.call # => LOUIS
```

#### Similar
1. **Strings separated by a slash**
  ```ruby
  PullChain.new(account, "user/name/upcase").call
  ```

2. **Use << operator**
  ```ruby
  chain = PullChain.new(account)
  chain << :user << :name << :upcase
  chain.call
  ```

3. **Use add method**
  ```ruby
  chain.add(:user).add(:name).add(:upcase).call
  ```

4. **Use add_all method**
  ```ruby
  chain.add_all(:user, :name, :upcase).call
  ```

#### Can exist nil value on the way, like a following case
```ruby
user.name = nil
chain.call # => nil
```

#### Insert, Delete, Clear
insert, insert_all method is insert_all method to chain.  
delete_at method is delete method from chain.  
clear method is delete all method from chain.

### Require arguments on method
Following example's method is require two arguments.  
What should do in this case?
```ruby
class Foo
  def say(speaker, message)
    puts "#{speaker} said '#{message}'"
  end
end
```
###### Solution
1. **Array, format is [Symbol, [\*Args]]**
  ```ruby
  chain = PullChain.new(Foo.new) << [:say, ["Andres", "Hello"]]
  chain.call # => Andres said 'Hello'
  ```

2. **String**
  ```ruby
  chain = PullChain.new(foo) << "say('John', 'Goodbye')"
  chain.call # => John said 'Goodbye'
  ```

### Require block on method
Following example's method is require Block.  
What should do in this case?
```ruby
[1,2,3,4,5].inject(3) { |sum, n| sum + n } # => 18
```

###### Solution

1. **Array, format is [Symbol, [\*Args, Proc]].**
  ```ruby
  chain = PullChain.new([1,2,3,4,5])
  chain << [:inject, [3, lambda { |sum, n| sum + n }]]
  chain.call # => 18
  ```

2. **String**
  ```ruby
  chain = PullChain.new([1,2,3,4,5])
  chain << "inject(3) { |sum, n| sum + n }"
  chain.call # => 18
  ```

### Use result on chain
Like a following example, can use result on chain.
```ruby
Foo = Struct.new(:bar)
Bar = Struct.new(:baz) {
  def speaker
    "Julian"
  end
}
class Baz
  def say(speaker, message)
    puts "#{speaker} said '#{message}'"
  end
end
foo = Foo.new(Bar.new(Baz.new))
```
###### Example: use result on chain

1. **String**  
  Can use bar instance in backward!
  ```ruby
  chain = PullChain.new(foo) << "bar/baz/say(bar.speaker, 'Good!')"
  chain.call # => Julian said 'Good!'
  ```
  Furthermore, can use variable name assigned.  
  @b is bar instance alias.
  ```ruby
  chain = PullChain.new(foo) << "@b = bar/baz/say(b.speaker, 'Cool')"
  chain.call # => Julian said 'Cool'
  ```

2. **Array**  
  Can access result by Proc.
  ```ruby
  chain = PullChain.new(foo) << :bar << :baz
  chain << [:say, Proc.new { next bar.speaker, "Oh" }]
  chain.call # => Julian said 'Oh'
  ```
  Case of use a lambda, can use result access object explicit.
  ```ruby
  chain = PullChain.new(foo) << :bar << :baz
  arg_reader = lambda { |accessor| next accessor.bar.speaker, "Oh" }
  chain << [:say, arg_reader]
  chain.call # => Julian said 'Oh'
  ```

#### etc
1. **How to use slash in strings separated by a slash**  
  Like following, please escaped by backslash.
  ```ruby
  chain = PullChain.new("AC") << "concat '\\/DC'"
  chain.call # => AC/DC
  ```
2. **Use return_nil_at_error= method, then can ignore error**
  ```ruby
  chain = PullChain.new("Test") << :xxx
  begin
      chain.call # => undefined method `xxx'
  rescue
  end
  chain.return_nil_at_error = true
  chain.call # => nil
  ```
3. **Note:use operator in chain**
  * **String type chain**
    ```ruby
    table = {name: %w(Bill Scott Paul)}
    PullChain.new(table, "[:name]").call # => [:name] NG
    PullChain.new(table, "self[:name]").call # => ["Bill", "Scott", "Paul"] OK
    ```
  * **Array type chain**
    ```ruby
    PullChain.new(table, [:[], [:name]]).call # OK
    ```

  Following is also the same.

  * **<< operator of String**
    ```ruby
    PullChain.new("Led", "<< ' Zeppelin'").call # NG syntax error
    PullChain.new("Led", "self << ' Zeppelin'").call # => "Led Zeppelin"
    ```

  * **[] operator of Array**
    ```ruby
    PullChain.new(%w(Donald Walter), "[1]").call # NG => [1]
    PullChain.new(%w(Donald Walter), "self[1]").call # OK => Walter
    ```

4. **Some classes, such Fixnum and Bignum not supported**  
  ```ruby
  PullChain.new(999999999999999, "self % 2").call # NG
  ```

---
## RelayChain
RelayChain is object like a connect to function's input from function's output.  
(methods well as can connect Proc.)

### Example
```ruby
class Decorator
  def decorate1(value)
    "( #{value} )"
  end
  def decorate2(value)
    "{ #{value} }"
  end
end

chain = RelayChain.new(Decorator.new, :decorate1, :decorate2)
chain.call("Hello") # => { ( Hello ) }
```
#### Similar
1. **Strings separated by a slash**
```ruby
  chain = RelayChain.new(Decorator.new, "decorate1/decorate2")
  chain.call("Hello")
```
2. **Use >> operator**
```ruby
  chain = RelayChain.new(Decorator.new)
  chain >> :decorate1 >> :decorate2
  chain.call("Hello")
```
3. **Use Method object**
```ruby
  chain = RelayChain.new
  chain >> decorator.method(:decorate1) >> decorator.method(:decorate2)
  chain.call("Hello")
```
4. **Use add method**
```ruby
  chain.add(:decorate1).add(:decorate2).call("Hello")
```
5. **Use add_all method**
```ruby
  chain.add_all(:decorate1, :decorate2).call("Hello")
```

#### Insert, Delete, Clear
insert, insert_all method is insert function to chain.  
delete_at method is delete function from chain.  
clear method is delete all function from chain.

### How to connect method of differed instance
Example, following two class.  
How to connect method of these class?
```ruby
class Decorator
  def decorate1(value)
    "( #{value} )"
  end
  def decorate2(value)
    "{ #{value} }"
  end
end

class Decorator2
  def decorate(value)
    "[ #{value} ]"
  end
end
```
###### Solution
1. **Array, format is [instance, Symbol or String of method]**
```ruby
  # Symbol ver.
  chain = RelayChain.new(Decorator.new)
  chain >> :decorate1 >> :decorate2 >> [Decorator2.new, :decorate]
  chain.call("Hello") # => [ { ( Hello ) } ]

  # String ver.
  chain = RelayChain.new(Decorator.new)
  chain >> :decorate1 >> :decorate2 >> [Decorator2.new, "decorate"]
  chain.call("Hello") # => [ { ( Hello ) } ]
```
2. **String, use registered instance**
```ruby
  chain = RelayChain.new(Decorator.new)

  # register name and instance
  chain.add_receiver("d2", Decorator2.new)

  # use registered instance
  chain >> "/decorate1/decorate2/d2.decorate"
  chain.call("Hello") # => [ { ( Hello ) } ]

  # add_receiver_table method is register name and instance at once.
  chain.add_receiver_table({"x" => X.new, "y" => Y.new})
```

### Case of method's output and method's input mismatch
Following example, decorate output is 1, and union input is 2.  
How to do connect these methods?
```ruby
class Decorator
  def decorate(value)
    "#{value} And"
  end
  def union(value1, value2)
    "#{value1} #{value2}"
  end
end
```
###### Solution
1. **Define connect method.**
```ruby
  class Decorator
    def connect(value)
      return value, "Palmer"
    end
  end
  chain = RelayChain.new(Decorator.new)
  chain >> :decorate >> :connect >> :union
  chain.call("Emerson, Lake") # => Emerson, Lake And Palmer
```
2. **Add lambda or Proc to between these methods.**  
  lambda's format is following.
```ruby
  # parameter: chain is chain object.  
  # parameter: \*args is previous functions output.
  lambda {|chain, *args| chain.call(next functions arguments) }.
```
  can call next function by chain object.
```ruby
  chain = RelayChain.new(Decorator.new)
  arg_adder = lambda { |chain, value| chain.call(value, "Jerry") }
  chain >> :decorate >> arg_adder >> :union
  chain.call("Tom") # => Tom And Jerry
```

### Appendix
**Chain stop by means of lambda.**
```ruby
class Decorator
  def decorate1(value)
    "( #{value} )"
  end

  def decorate2(value)
    "{ #{value} }"
  end
end

def create_stopper(&stop_condition)
  lambda do |chain, value|
    # if stop conditions are met then return value
    if stop_condition.call(value)
      value
    else
      chain.call(value)
    end
  end
end

chain = RelayChain.new(Decorator.new, :decorate1, :decorate2)

# insert_all conditional chain stopper
chain.insert(1, create_stopper { |value| value =~ /\d/ })
chain.call("Van Halen 1984") # => ( Van Halen 1984 )     not enclosed to {}
chain.call("Van Halen Jump") # => { ( Van Halen Jump ) } enclosed to {}
```

## License
Released under the MIT License.
