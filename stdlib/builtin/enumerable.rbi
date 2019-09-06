# The `Enumerable` mixin provides collection classes with several
# traversal and searching methods, and with the ability to sort. The class
# must provide a method `each`, which yields successive members of the
# collection. If `Enumerable#max`, `#min`, or `#sort` is used, the
# objects in the collection must also implement a meaningful `<=>`
# operator, as these methods rely on an ordering between members of the
# collection.
module Enumerable[Elem]
  def each: () { (Elem arg0) -> any } -> any
          | () -> self

  # Passes each element of the collection to the given block. The method
  # returns `true` if the block never returns `false` or `nil` . If the
  # block is not given, Ruby adds an implicit block of `{ |obj| obj }` which
  # will cause [all?](Enumerable.downloaded.ruby_doc#method-i-all-3F) to
  # return `true` when none of the collection members are `false` or `nil` .
  # 
  # If instead a pattern is supplied, the method returns whether `pattern
  # === element` for every collection member.
  # 
  #     %w[ant bear cat].all? { |word| word.length >= 3 } #=> true
  #     %w[ant bear cat].all? { |word| word.length >= 4 } #=> false
  #     %w[ant bear cat].all?(/t/)                        #=> false
  #     [1, 2i, 3.14].all?(Numeric)                       #=> true
  #     [nil, true, 99].all?                              #=> false
  #     [].all?                                           #=> true
  def all?: () -> bool
          | () { (Elem arg0) -> any } -> bool

  # Passes each element of the collection to the given block. The method
  # returns `true` if the block ever returns a value other than `false` or
  # `nil` . If the block is not given, Ruby adds an implicit block of `{
  # |obj| obj }` that will cause
  # [any?](Enumerable.downloaded.ruby_doc#method-i-any-3F) to return `true`
  # if at least one of the collection members is not `false` or `nil` .
  # 
  # If instead a pattern is supplied, the method returns whether `pattern
  # === element` for any collection member.
  # 
  # ```ruby
  # %w[ant bear cat].any? { |word| word.length >= 3 } #=> true
  # %w[ant bear cat].any? { |word| word.length >= 4 } #=> true
  # %w[ant bear cat].any?(/d/)                        #=> false
  # [nil, true, 99].any?(Integer)                     #=> true
  # [nil, true, 99].any?                              #=> true
  # [].any?                                           #=> false
  # ```
  def `any?`: () -> bool
            | () { (Elem arg0) -> any } -> bool

  def collect: [U] () { (Elem arg0) -> U } -> ::Array[U]
             | () -> T::Enumerator[Elem]

  def collect_concat: [U] () { (Elem arg0) -> T::Enumerator[U] } -> ::Array[U]

  # Returns the number of items in `enum` through enumeration. If an
  # argument is given, the number of items in `enum` that are equal to
  # `item` are counted. If a block is given, it counts the number of
  # elements yielding a true value.
  # 
  # ```ruby
  # ary = [1, 2, 4, 2]
  # ary.count               #=> 4
  # ary.count(2)            #=> 2
  # ary.count{ |x| x%2==0 } #=> 3
  # ```
  def count: () -> Integer
           | (?any arg0) -> Integer
           | () { (Elem arg0) -> any } -> Integer

  def cycle: (?Integer n) { (Elem arg0) -> any } -> NilClass
           | (?Integer n) -> T::Enumerator[Elem]

  def detect: (?Proc ifnone) { (Elem arg0) -> any } -> Elem?
            | (?Proc ifnone) -> T::Enumerator[Elem]

  def drop: (Integer n) -> ::Array[Elem]

  def drop_while: () { (Elem arg0) -> any } -> ::Array[Elem]
                | () -> T::Enumerator[Elem]

  def each_cons: (Integer n) { (::Array[Elem] arg0) -> any } -> NilClass
               | (Integer n) -> T::Enumerator[::Array[Elem]]

  def each_with_index: () { (Elem arg0, Integer arg1) -> any } -> T::Enumerable[Elem]
                     | () -> T::Enumerator[[ Elem, Integer ]]

  def each_with_object: [U] (U arg0) { (Elem arg0, any arg1) -> any } -> U
                      | [U] (U arg0) -> T::Enumerator[[ Elem, U ]]

  # Returns an array containing the items in *enum* .
  # 
  # ```ruby
  # (1..7).to_a                       #=> [1, 2, 3, 4, 5, 6, 7]
  # { 'a'=>1, 'b'=>2, 'c'=>3 }.to_a   #=> [["a", 1], ["b", 2], ["c", 3]]
  # 
  # require 'prime'
  # Prime.entries 10                  #=> [2, 3, 5, 7]
  # ```
  def entries: () -> ::Array[Elem]

  def find_all: () { (Elem arg0) -> any } -> ::Array[Elem]
              | () -> T::Enumerator[Elem]

  def find_index: (?any value) -> Integer?
                | () { (Elem arg0) -> any } -> Integer?
                | () -> T::Enumerator[Elem]

  # Returns the first element, or the first `n` elements, of the enumerable.
  # If the enumerable is empty, the first form returns `nil`, and the
  # second form returns an empty array.
  # 
  # ```ruby
  # %w[foo bar baz].first     #=> "foo"
  # %w[foo bar baz].first(2)  #=> ["foo", "bar"]
  # %w[foo bar baz].first(10) #=> ["foo", "bar", "baz"]
  # [].first                  #=> nil
  # [].first(10)              #=> []
  # ```
  def first: () -> Elem?
           | (?Integer n) -> ::Array[Elem]?

  def grep: (any arg0) -> ::Array[Elem]
          | [U] (any arg0) { (Elem arg0) -> U } -> ::Array[U]

  def group_by: [U] () { (Elem arg0) -> U } -> ::Hash[U, ::Array[Elem]]
              | () -> T::Enumerator[Elem]

  def `include?`: (any arg0) -> bool

  def inject: [Any] (?Any initial, ?Symbol arg0) -> any
            | (?Symbol arg0) -> any
            | (?Elem initial) { (Elem arg0, Elem arg1) -> Elem } -> Elem
            | () { (Elem arg0, Elem arg1) -> Elem } -> Elem?

  # Returns the object in *enum* with the maximum value. The first form
  # assumes all objects implement `Comparable` ; the second uses the block
  # to return *a \<=\> b* .
  # 
  # ```ruby
  # a = %w(albatross dog horse)
  # a.max                                   #=> "horse"
  # a.max { |a, b| a.length <=> b.length }  #=> "albatross"
  # ```
  # 
  # If the `n` argument is given, maximum `n` elements are returned as an
  # array, sorted in descending order.
  # 
  # ```ruby
  # a = %w[albatross dog horse]
  # a.max(2)                                  #=> ["horse", "dog"]
  # a.max(2) {|a, b| a.length <=> b.length }  #=> ["albatross", "horse"]
  # [5, 1, 3, 4, 2].max(3)                    #=> [5, 4, 3]
  # ```
  def max: () -> Elem?
         | () { (Elem arg0, Elem arg1) -> Integer } -> Elem?
         | (?Integer arg0) -> ::Array[Elem]
         | (?Integer arg0) { (Elem arg0, Elem arg1) -> Integer } -> ::Array[Elem]

  def max_by: () -> T::Enumerator[Elem]
            | () { (Elem arg0) -> (Comparable | ::Array[any]) } -> Elem?
            | (?Integer arg0) -> T::Enumerator[Elem]
            | (?Integer arg0) { (Elem arg0) -> (Comparable | ::Array[any]) } -> ::Array[Elem]

  # Returns the object in *enum* with the minimum value. The first form
  # assumes all objects implement `Comparable` ; the second uses the block
  # to return *a \<=\> b* .
  # 
  # ```ruby
  # a = %w(albatross dog horse)
  # a.min                                   #=> "albatross"
  # a.min { |a, b| a.length <=> b.length }  #=> "dog"
  # ```
  # 
  # If the `n` argument is given, minimum `n` elements are returned as a
  # sorted array.
  # 
  # ```ruby
  # a = %w[albatross dog horse]
  # a.min(2)                                  #=> ["albatross", "dog"]
  # a.min(2) {|a, b| a.length <=> b.length }  #=> ["dog", "horse"]
  # [5, 1, 3, 4, 2].min(3)                    #=> [1, 2, 3]
  # ```
  def min: () -> Elem?
         | () { (Elem arg0, Elem arg1) -> Integer } -> Elem?
         | (?Integer arg0) -> ::Array[Elem]
         | (?Integer arg0) { (Elem arg0, Elem arg1) -> Integer } -> ::Array[Elem]

  def min_by: () -> T::Enumerator[Elem]
            | () { (Elem arg0) -> (Comparable | ::Array[any]) } -> Elem?
            | (?Integer arg0) -> T::Enumerator[Elem]
            | (?Integer arg0) { (Elem arg0) -> (Comparable | ::Array[any]) } -> ::Array[Elem]

  # Returns a two element array which contains the minimum and the maximum
  # value in the enumerable. The first form assumes all objects implement
  # `Comparable` ; the second uses the block to return *a \<=\> b* .
  # 
  # ```ruby
  # a = %w(albatross dog horse)
  # a.minmax                                  #=> ["albatross", "horse"]
  # a.minmax { |a, b| a.length <=> b.length } #=> ["dog", "albatross"]
  # ```
  def minmax: () -> [ Elem?, Elem? ]
            | () { (Elem arg0, Elem arg1) -> Integer } -> [ Elem?, Elem? ]

  def minmax_by: () -> [ Elem?, Elem? ]
               | () { (Elem arg0) -> (Comparable | ::Array[any]) } -> T::Enumerator[Elem]

  # Passes each element of the collection to the given block. The method
  # returns `true` if the block never returns `true` for all elements. If
  # the block is not given, `none?` will return `true` only if none of the
  # collection members is true.
  # 
  # If instead a pattern is supplied, the method returns whether `pattern
  # === element` for none of the collection members.
  # 
  # ```ruby
  # %w{ant bear cat}.none? { |word| word.length == 5 } #=> true
  # %w{ant bear cat}.none? { |word| word.length >= 4 } #=> false
  # %w{ant bear cat}.none?(/d/)                        #=> true
  # [1, 3.14, 42].none?(Float)                         #=> false
  # [].none?                                           #=> true
  # [nil].none?                                        #=> true
  # [nil, false].none?                                 #=> true
  # [nil, false, true].none?                           #=> false
  # ```
  def none?: () -> bool
           | () { (Elem arg0) -> any } -> bool

  # Passes each element of the collection to the given block. The method
  # returns `true` if the block returns `true` exactly once. If the block is
  # not given, `one?` will return `true` only if exactly one of the
  # collection members is true.
  # 
  # If instead a pattern is supplied, the method returns whether `pattern
  # === element` for exactly one collection member.
  # 
  # ```ruby
  # %w{ant bear cat}.one? { |word| word.length == 4 }  #=> true
  # %w{ant bear cat}.one? { |word| word.length > 4 }   #=> false
  # %w{ant bear cat}.one? { |word| word.length < 4 }   #=> false
  # %w{ant bear cat}.one?(/t/)                         #=> false
  # [ nil, true, 99 ].one?                             #=> false
  # [ nil, true, false ].one?                          #=> true
  # [ nil, true, 99 ].one?(Integer)                    #=> true
  # [].one?                                            #=> false
  # ```
  def one?: () -> bool
          | () { (Elem arg0) -> any } -> bool

  def partition: () { (Elem arg0) -> any } -> [ ::Array[Elem], ::Array[Elem] ]
               | () -> T::Enumerator[Elem]

  def reject: () { (Elem arg0) -> any } -> ::Array[Elem]
            | () -> T::Enumerator[Elem]

  def reverse_each: () { (Elem arg0) -> any } -> T::Enumerator[Elem]
                  | () -> T::Enumerator[Elem]

  # Returns an array containing the items in *enum* sorted.
  # 
  # Comparisons for the sort will be done using the items’ own `<=>`
  # operator or using an optional code block.
  # 
  # The block must implement a comparison between `a` and `b` and return an
  # integer less than 0 when `b` follows `a`, `0` when `a` and `b` are
  # equivalent, or an integer greater than 0 when `a` follows `b` .
  # 
  # The result is not guaranteed to be stable. When the comparison of two
  # elements returns `0`, the order of the elements is unpredictable.
  # 
  # ```ruby
  # %w(rhea kea flea).sort           #=> ["flea", "kea", "rhea"]
  # (1..10).sort { |a, b| b <=> a }  #=> [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  # ```
  # 
  # See also [\#sort\_by](Enumerable.downloaded.ruby_doc#method-i-sort_by).
  # It implements a Schwartzian transform which is useful when key
  # computation or comparison is expensive.
  def sort: () -> ::Array[Elem]
          | () { (Elem arg0, Elem arg1) -> Integer } -> ::Array[Elem]

  def sort_by: () { (Elem arg0) -> (Comparable | ::Array[any]) } -> ::Array[Elem]
             | () -> T::Enumerator[Elem]

  def take: (Integer n) -> ::Array[Elem]?

  def take_while: () { (Elem arg0) -> any } -> ::Array[Elem]
                | () -> T::Enumerator[Elem]

  # Implemented in C++
  # Returns the result of interpreting *enum* as a list of `[key, value]`
  # pairs.
  # 
  #     %i[hello world].each_with_index.to_h
  #       # => {:hello => 0, :world => 1}
  # 
  # If a block is given, the results of the block on each element of the
  # enum will be used as pairs.
  # 
  # ```ruby
  # (1..5).to_h {|x| [x, x ** 2]}
  #   #=> {1=>1, 2=>4, 3=>9, 4=>16, 5=>25}
  # ```
  def to_h: () -> ::Hash[any, any]

  def each_slice: (Integer n) { (::Array[Elem] arg0) -> any } -> NilClass
                | (Integer n) -> T::Enumerator[::Array[Elem]]

  def find: (?Proc ifnone) { (Elem arg0) -> any } -> Elem?
          | (?Proc ifnone) -> T::Enumerator[Elem]

  def flat_map: [U] () { (Elem arg0) -> U } -> U
              | () -> T::Enumerator[Elem]

  def map: [U] () { (Elem arg0) -> U } -> ::Array[U]
         | () -> T::Enumerator[Elem]

  def member?: (any arg0) -> bool

  def reduce: [Any] (?Any initial, ?Symbol arg0) -> any
            | (?Symbol arg0) -> any
            | (?Elem initial) { (Elem arg0, Elem arg1) -> Elem } -> Elem
            | () { (Elem arg0, Elem arg1) -> Elem } -> Elem?

  def select: () { (Elem arg0) -> any } -> ::Array[Elem]
            | () -> T::Enumerator[Elem]

  # Returns an array containing the items in *enum* .
  # 
  # ```ruby
  # (1..7).to_a                       #=> [1, 2, 3, 4, 5, 6, 7]
  # { 'a'=>1, 'b'=>2, 'c'=>3 }.to_a   #=> [["a", 1], ["b", 2], ["c", 3]]
  # 
  # require 'prime'
  # Prime.entries 10                  #=> [2, 3, 5, 7]
  # ```
  def to_a: () -> ::Array[Elem]

  # Returns a lazy enumerator, whose methods map/collect,
  # flat\_map/collect\_concat, select/find\_all, reject, grep,
  # [\#grep\_v](Enumerable.downloaded.ruby_doc#method-i-grep_v), zip, take,
  # [\#take\_while](Enumerable.downloaded.ruby_doc#method-i-take_while),
  # drop, and
  # [\#drop\_while](Enumerable.downloaded.ruby_doc#method-i-drop_while)
  # enumerate values only on an as-needed basis. However, if a block is
  # given to zip, values are enumerated immediately.
  # 
  # 
  # The following program finds pythagorean triples:
  # 
  # ```ruby
  # def pythagorean_triples
  #   (1..Float::INFINITY).lazy.flat_map {|z|
  #     (1..z).flat_map {|x|
  #       (x..z).select {|y|
  #         x**2 + y**2 == z**2
  #       }.map {|y|
  #         [x, y, z]
  #       }
  #     }
  #   }
  # end
  # # show first ten pythagorean triples
  # p pythagorean_triples.take(10).force # take is lazy, so force is needed
  # p pythagorean_triples.first(10)      # first is eager
  # # show pythagorean triples less than 100
  # p pythagorean_triples.take_while { |*, z| z < 100 }.force
  # ```
  def lazy: () -> Enumerator::Lazy[Elem]
end
