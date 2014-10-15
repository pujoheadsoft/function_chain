require "spec_helper"

describe FunctionChain::PullChain do

  before(:context) do
    City = Struct.new(:bookstore)
    BookStore = Struct.new(:shelves, :recommended_shelf)
    Shelf = Struct.new(:books, :recommended_book_num)
    Book = Struct.new(:title, :author)

    programing_books = []
    programing_books << Book.new("The Ruby Programming Language",
                                 "David Flanagan and Yukihiro Matsumoto")
    programing_books << Book.new("Ruby Best Practices", "Gregory T Brown")
    programing_books << Book.new("Metaprogramming Ruby", "Paolo Perrotta")

    mystery_books = []
    mystery_books << Book.new("And Then There Were None", "Agatha Christie")
    mystery_books << Book.new("Tragedy of X", "Ellery Queen")

    shelves = {
      programing: Shelf.new(programing_books, 0),
      mystery: Shelf.new(mystery_books, 1)
    }
    @city = City.new(BookStore.new(shelves, :mystery))

    class Concatter
      def concat(value1, value2)
        "#{value1} to #{value2}"
      end
    end
    @concatter = Concatter.new

    PullChain = FunctionChain::PullChain
  end

  it "[success case] symbol type function" do
    chain = PullChain.new(@city) << :bookstore << :shelves
    expect(chain.call).to eq(@city.bookstore.shelves)
  end

  it "[success case] array type function with args [:symbol, [args]]" do
    chain = PullChain.new(@city)
    chain << :bookstore << :shelves << [:[], [:mystery]]
    expect(chain.call).to eq(@city.bookstore.shelves[:mystery])
  end

  it "[success case] array type function with args [:symbol, [proc]" do
    chain = PullChain.new([1, 2, 3, 4, 5])
    chain << [:find_all, [lambda { |n| n.even? }]]
    expect(chain.call).to eq([2, 4])
  end

  it "[success case] array type function with args [:symbol, [arg, proc]]" do
    chain = PullChain.new([1, 2, 3, 4, 5])
    chain << [:inject, [0, lambda { |sum, n| sum + n  }]]
    expect(chain.call).to eq(15)
  end

  it "[success case] array type function with args [:symbol, [args, proc]]" do
    chain = PullChain.new(self)
    def block_caller(v1, v2, v3, v4, &block)
      block.call(v1, v2, v3, v4)
    end
    union_args = lambda { |v1, v2, v3, v4| "#{v1}&#{v2}&#{v3}&#{v4}" }
    chain << [:block_caller, [2, 4, 6, 8, union_args]]
    expect(chain.call).to eq("2&4&6&8")
  end

  it "[success case] array type function with proc [:symbol, Proc]" do
    chain = PullChain.new(@city) << :bookstore
    chain << :shelves << [:[], Proc.new { |_| bookstore.recommended_shelf }]
    expect(chain.call).to eq(@city.bookstore.shelves[:mystery])
  end

  it "[success case] array type function with proc(return multi value)" do
    chain = PullChain.new(@concatter)
    chain << [:concat, Proc.new { next "Stairway", "Heaven" }]
    expect(chain.call).to eq(@concatter.concat("Stairway", "Heaven"))
  end

  it "[success case] string type function" do
    chain = PullChain.new(@city)
    chain << "/bookstore/shelves[:programing]/books[1]/title"
    title = @city.bookstore.shelves[:programing].books[1].title
    expect(chain.call).to eq(title)
  end

  it "[success case] string type function, add a plurality of times" do
    chain = PullChain.new(@city)
    chain << "/bookstore/shelves[:programing]"
    chain << "/books[1]/title"
    title = @city.bookstore.shelves[:programing].books[1].title
    expect(chain.call).to eq(title)
  end

  it "[success case] string type function, with reference" do
    chain = PullChain.new(@city)
    chain << "/bookstore/shelves[bookstore.recommended_shelf]/books[0]/author"
    store = @city.bookstore
    author = @city.bookstore.shelves[store.recommended_shelf].books[0].author
    expect(chain.call).to eq(author)
  end

  it "[success case] string type function, with reference & assign variable" do
    chain = PullChain.new(@city)
    chain << "/bookstore/@shelf = shelves[:mystery]"
    chain << "/books[shelf.recommended_book_num]/title"
    shelf = @city.bookstore.shelves[:mystery]
    title = shelf.books[shelf.recommended_book_num].title
    expect(chain.call).to eq(title)
  end

  it "[success case] string type function, with escaped /" do
    chain = PullChain.new("AC") << "concat '\\/DC'"
    expect(chain.call).to eq("AC".concat("/DC"))
  end

  it "[success case] mix type string, symbol, array" do
    chain = PullChain.new(@city)
    chain.add_all(:bookstore, "shelves[:programing]")
    chain << "books" << [:[], [0]] << :title
    title = @city.bookstore.shelves[:programing].books[0].title
    expect(chain.call).to eq(title)
  end

  it "[success case] insert_all" do
    chain = PullChain.new(@city, "/bookstore/shelves[:programing]/title")
    chain.insert(2, "books[1]")
    title = @city.bookstore.shelves[:programing].books[1].title
    expect(chain.call).to eq(title)
  end

  it "[success case] inserts" do
    chain = PullChain.new(@city, "/bookstore/title")
    chain.insert_all(1, "shelves[:programing]", "books[1]")
    title = @city.bookstore.shelves[:programing].books[1].title
    expect(chain.call).to eq(title)
  end

  it "[success case] delete" do
    chain = PullChain.new(@city, "/bookstore/shelves[:programing]/title")
    chain.delete_at(2)
    expect(chain.call).to eq(@city.bookstore.shelves[:programing])
  end

  it "[success case] clear" do
    chain = PullChain.new(@city, "/bookstore/shelves[:programing]/title")
    chain.clear
    expect(chain.call).to eq(@city)
  end

  it "[success case] get a value of not exist key" do
    chain = PullChain.new(@city)
    chain << "/bookstore/shelves['not exist key']/books[1]/title"
    expect(chain.call).to be_nil
  end

  it "[success case] get a nil at error(symbol)" do
    chain = PullChain.new(@city) << :aaaa << :bbbb
    chain.return_nil_at_error = true
    expect(chain.call).to be_nil
  end

  it "[success case] get a nil at error(string)" do
    chain = PullChain.new(@city) << "/bookstore/xyz/afasd"
    chain.return_nil_at_error = true
    expect(chain.call).to be_nil
  end

  it "[success case] get a nil at error(array)" do
    chain = PullChain.new(@city) << :bookstore << :shelves << [:x, [:mystery]]
    chain.return_nil_at_error = true
    expect(chain.call).to be_nil
  end

  it "[success case] get a false" do
    chain = PullChain.new(Object.new) << :nil? << :to_s << :upcase
    expect(chain.call).to eq(false.to_s.upcase)
  end

  it "[success case] to_s" do
    chain = PullChain.new(@city) << "bookstore/shelves[:programing]"
    chain << :books << [:[], [1]] << :title
    names = ["bookstore", "shelves[:programing]", :books, [:[], [1]], :title]
    expect(chain.to_s).to eq("#{PullChain}#{names}")
  end

  it "[fail case] NameError" do
    expect do
      FunctionChain.pull(@city, "/bookstore/shelvesassss/")
    end.to raise_error(NameError)
  end

  it "[fail case] NoMethodError" do
    expect do
      FunctionChain.pull(@city, :bookstore, :create_common_chain_element)
    end.to raise_error(NoMethodError)
  end

  it "[fail case] ArgumentError:add not supported type" do
    expect do
      FunctionChain.pull(@city, :bookstore, 100)
    end.to raise_error(ArgumentError)
  end

  it "[fail case] ArgumentError:array format wrong 1" do
    expect do
      FunctionChain.pull(@city, :bookstore, :shelves, [:[]])
    end.to raise_error(ArgumentError)
  end

  it "[fail case] ArgumentError:array format wrong 2" do
    expect do
      FunctionChain.pull(@city, :bookstore, :shelves, [:[], 1])
    end.to raise_error(ArgumentError)
  end

  it "[fail case] ArgumentError:wrong format variable define 1" do
    expect do
      chain = PullChain.new(@city)
      chain << "/bookstore/@1shelf = shelves[:mystery]/books[0]/title"
      chain.call
    end.to raise_error(ArgumentError)
  end

  %w(! " ' # % & ( ) = ~ \\ ` @ [ ] * + < > ? 1 ; : . , ^).each do |e|
    it "[fail case] ArgumentError:wrong format variable define #{e}" do
      expect do
        FunctionChain.pull(@city, "/@#{e}x = bookstore")
      end.to raise_error(ArgumentError)
    end
  end

end

describe FunctionChain::RelayChain do

  before(:context) do

    class Decorator
      def decorate1(value)
        "#{value} is decorated"
      end

      def decorate2(value)
        "#{value} is more decorated"
      end
    end

    class EncloseDecorator
      def decorate(value)
        "'#{value}'"
      end
    end

    class PrefixSuffixDecorator
      def decorate(value, prefix, suffix)
        "#{prefix}#{value}#{suffix}"
      end
    end

    class MultivalueIO
      def four_values
        return "value1", [1, 2, 3, 4], [4, 3, 2, 1], "value4"
      end

      def union_four_values(value1, array1, array2, value4)
        "#{value1} & #{array1} & #{array2} & #{value4}"
      end
    end

    @decorator = Decorator.new
    @enclose_decorator = EncloseDecorator.new
    @prefix_suffix_decorator = PrefixSuffixDecorator.new
    @multivalue_io = MultivalueIO.new
    RelayChain = FunctionChain::RelayChain
  end

  it "[success case] same instance, use symbol" do
    chain = RelayChain.new(@decorator) >> :decorate1 >> :decorate2
    decorated_value = @decorator.decorate2(@decorator.decorate1("Evans"))
    expect(chain.call("Evans")).to eq(decorated_value)
  end

  it "[success case] same instance, use string" do
    chain = RelayChain.new(@decorator, "decorate1/decorate2")
    decorated_value = @decorator.decorate2(@decorator.decorate1("Davis"))
    expect(chain.call("Davis")).to eq(decorated_value)
  end

  it "[success case] same instance, insert_all" do
    chain = RelayChain.new(@decorator) >> :decorate2
    chain.insert(0, :decorate1)
    decorated_value = @decorator.decorate2(@decorator.decorate1("Coltrane"))
    expect(chain.call("Coltrane")).to eq(decorated_value)
  end

  it "[success case] same instance, delete" do
    chain = RelayChain.new(@decorator) >> :decorate1 >> :decorate2
    chain.delete_at(0)
    expect(chain.call("Petrucciani")).to eq(@decorator.decorate2("Petrucciani"))
  end

  it "[success case] same instance, clear" do
    chain = RelayChain.new(@decorator) >> :decorate1 >> :decorate2
    chain.clear
    expect(chain.call("Petrucciani")).to be_nil
  end

  it "[success case] same instance, multiple io" do
    chain = RelayChain.new(@multivalue_io) >> :four_values >> :union_four_values
    value = @multivalue_io.union_four_values(*@multivalue_io.four_values)
    expect(chain.call).to eq(value)
  end

  it "[success case] differ instance" do
    chain = RelayChain.new(@decorator, :decorate1)
    chain.add_all(:decorate2, [@enclose_decorator, :decorate])
    decorated_value = @decorator.decorate2(@decorator.decorate1("Peterson"))
    decorated_value = @enclose_decorator.decorate(decorated_value)
    expect(chain.call("Peterson")).to eq(decorated_value)
  end

  it "[success case] differ instance, designate of method name as string" do
    chain = RelayChain.new(@decorator, :decorate1)
    chain.add_all(:decorate2, [@enclose_decorator, "decorate"])
    decorated_value = @decorator.decorate2(@decorator.decorate1("Peterson"))
    decorated_value = @enclose_decorator.decorate(decorated_value)
    expect(chain.call("Peterson")).to eq(decorated_value)
  end

  it "[success case] differ instance use string & add receiver" do
    chain = RelayChain.new(@decorator)
    chain >> "decorate1/decorate2/e_decorator.decorate"
    chain.add_receiver("e_decorator", @enclose_decorator)
    decorated_value = @decorator.decorate2(@decorator.decorate1("Brown"))
    decorated_value = @enclose_decorator.decorate(decorated_value)
    expect(chain.call("Brown")).to eq(decorated_value)
  end

  it "[success case] connect to methods that the different num of argument" do
    connector = lambda { |c, value| c.call(value, "Bernard", "Purdie") }
    chain = RelayChain.new >> [@enclose_decorator, :decorate]
    chain >> connector >> [@prefix_suffix_decorator, :decorate]
    decorated_value = @enclose_decorator.decorate("Pretty")
    decorated_value = @prefix_suffix_decorator.decorate(decorated_value,
                                                        "Bernard", "Purdie")
    expect(chain.call("Pretty")).to eq(decorated_value)
  end

  it "[success case] differ instance, use str & connector & receiver_table" do
    chain = RelayChain.new(@decorator)
    chain.add_receiver_table("e_decorator" => @enclose_decorator,
                             "ps_decorator" => @prefix_suffix_decorator)
    connector = lambda { |c, value| c.call(value, "I Say ", ".") }
    chain >> "decorate1/e_decorator.decorate"
    chain >> connector >> "ps_decorator.decorate"

    value = @enclose_decorator.decorate(@decorator.decorate1("Cake"))
    value = @prefix_suffix_decorator.decorate(value, "I Say ", ".")
    expect(chain.call("Cake")).to eq(value)
  end

  it "[success case] differ instance, use Method" do
    chain = RelayChain.new
    chain >> @decorator.method(:decorate1)
    chain >> @enclose_decorator.method(:decorate)
    v = @enclose_decorator.decorate(@decorator.decorate1("Skunk"))
    expect(chain.call("Skunk")).to eq(v)
  end

  it "[success case] use Proc" do
    process1 = lambda { |chain, arr| chain.call(arr.select(&:even?)) }
    process2 = lambda { |_, arr| arr.map { |num| num * 10 } }
    chain = RelayChain.new >> process1 >> process2
    array = [1, 2, 3, 4, 5]
    value = array.select(&:even?).map { |num| num * 10 }
    expect(chain.call(array)).to eq(value)
  end

  it "[success case] stop of chain" do
    chain = RelayChain.new(@decorator)
    chain.add_all(:decorate1, :decorate2, [@enclose_decorator, :decorate])
    stopper = lambda { |_, value| value }
    chain.insert(2, stopper)
    decorated_value = @decorator.decorate2(@decorator.decorate1("Montgomery"))
    expect(chain.call("Montgomery")).to eq(decorated_value)
  end

  it "[success case] to_s" do
    chain = RelayChain.new
    stopper = lambda { |_, value| value }
    chain >> @decorator.method(:decorate1) >> stopper
    names = [@decorator.method(:decorate1), stopper]
    expect(chain.to_s).to eq("#{RelayChain}#{names}")
  end

  it "[fail case] ArgumentError:add not supported type" do
    expect do
      RelayChain.new(@decorator) >> :decorate1 >> 100
    end.to raise_error(ArgumentError)
  end

  it "[fail case] ArgumentError: wrong number of array's element" do
    expect do
      RelayChain.new(@decorator) >> [@enclose_decorator]
    end.to raise_error(ArgumentError)
  end

  it "[fail case] ArgumentError: wrong type of array's second element" do
    expect do
      RelayChain.new(@decorator) >> [@enclose_decorator, 10]
    end.to raise_error(ArgumentError)
  end

end
