# [Numeric](Numeric) is the class from which all
# higher-level numeric classes should inherit.
# 
# [Numeric](Numeric) allows instantiation of
# heap-allocated objects. Other core numeric classes such as
# [Integer](https://ruby-doc.org/core-2.6.3/Integer.html) are implemented
# as immediates, which means that each
# [Integer](https://ruby-doc.org/core-2.6.3/Integer.html) is a single
# immutable object which is always passed by value.
# 
# ```ruby
# a = 1
# 1.object_id == a.object_id   #=> true
# ```
# 
# There can only ever be one instance of the integer `1`, for example.
# Ruby ensures this by preventing instantiation. If duplication is
# attempted, the same instance is returned.
# 
# ```ruby
# Integer.new(1)                   #=> NoMethodError: undefined method `new' for Integer:Class
# 1.dup                            #=> 1
# 1.object_id == 1.dup.object_id   #=> true
# ```
# 
# For this reason, [Numeric](Numeric) should be used
# when defining other numeric classes.
# 
# Classes which inherit from [Numeric](Numeric) must
# implement `coerce`, which returns a two-member
# [Array](https://ruby-doc.org/core-2.6.3/Array.html) containing an object
# that has been coerced into an instance of the new class and `self` (see
# [coerce](Numeric#method-i-coerce) ).
# 
# Inheriting classes should also implement arithmetic operator methods (
# `+`, `-`, `*` and `/` ) and the `<=>` operator (see
# [Comparable](https://ruby-doc.org/core-2.6.3/Comparable.html) ). These
# methods may rely on `coerce` to ensure interoperability with instances
# of other numeric classes.
# 
# ```ruby
# class Tally < Numeric
#   def initialize(string)
#     @string = string
#   end
# 
#   def to_s
#     @string
#   end
# 
#   def to_i
#     @string.size
#   end
# 
#   def coerce(other)
#     [self.class.new('|' * other.to_i), self]
#   end
# 
#   def <=>(other)
#     to_i <=> other.to_i
#   end
# 
#   def +(other)
#     self.class.new('|' * (to_i + other.to_i))
#   end
# 
#   def -(other)
#     self.class.new('|' * (to_i - other.to_i))
#   end
# 
#   def *(other)
#     self.class.new('|' * (to_i * other.to_i))
#   end
# 
#   def /(other)
#     self.class.new('|' * (to_i / other.to_i))
#   end
# end
# 
# tally = Tally.new('||')
# puts tally * 2            #=> "||||"
# puts tally > 1            #=> true
# ```
class Numeric < Object
  include Comparable

  def %: (Numeric arg0) -> Numeric

  def +: (Numeric arg0) -> Numeric

  # Unary Plus—Returns the receiver.
  def +@: () -> Numeric

  def -: (Numeric arg0) -> Numeric

  def *: (Numeric arg0) -> Numeric

  def /: (Numeric arg0) -> Numeric

  def -@: () -> Numeric

  def <: (Numeric arg0) -> bool

  def <=: (Numeric arg0) -> bool

  def <=>: (Numeric arg0) -> Integer

  def >: (Numeric arg0) -> bool

  def >=: (Numeric arg0) -> bool

  # Returns the absolute value of `num` .
  # 
  # ```ruby
  # 12.abs         #=> 12
  # (-34.56).abs   #=> 34.56
  # -34.56.abs     #=> 34.56
  # ```
  # 
  # [\#magnitude](Numeric.downloaded.ruby_doc#method-i-magnitude) is an
  # alias for [\#abs](Numeric.downloaded.ruby_doc#method-i-abs).
  def abs: () -> Numeric

  # Returns square of self.
  def abs2: () -> Numeric

  # Returns 0 if the value is positive, pi otherwise.
  def angle: () -> Numeric

  # Returns 0 if the value is positive, pi otherwise.
  def arg: () -> Numeric

  # Returns the smallest number greater than or equal to `num` with a
  # precision of `ndigits` decimal digits (default: 0).
  # 
  # [Numeric](Numeric.downloaded.ruby_doc) implements this by converting its
  # value to a [Float](https://ruby-doc.org/core-2.6.3/Float.html) and
  # invoking
  # [Float\#ceil](https://ruby-doc.org/core-2.6.3/Float.html#method-i-ceil)
  # .
  def ceil: () -> Integer
          | (?Integer digits) -> Numeric

  def coerce: (Numeric arg0) -> [ Numeric, Numeric ]

  # Returns self.
  def conj: () -> Numeric

  # Returns self.
  def conjugate: () -> Numeric

  # Returns the denominator (always positive).
  def denominator: () -> Integer

  def div: (Numeric arg0) -> Integer

  def divmod: (Numeric arg0) -> [ Numeric, Numeric ]

  def eql?: (Numeric arg0) -> bool

  def fdiv: (Numeric arg0) -> Numeric

  # Returns the largest number less than or equal to `num` with a precision
  # of `ndigits` decimal digits (default: 0).
  # 
  # [Numeric](Numeric.downloaded.ruby_doc) implements this by converting its
  # value to a [Float](https://ruby-doc.org/core-2.6.3/Float.html) and
  # invoking
  # [Float\#floor](https://ruby-doc.org/core-2.6.3/Float.html#method-i-floor)
  # .
  def floor: () -> Integer
           | (?Integer digits) -> Numeric

  # Returns the corresponding imaginary number. Not available for complex
  # numbers.
  # 
  # ```ruby
  # -42.i  #=> (0-42i)
  # 2.0.i  #=> (0+2.0i)
  # ```
  def i: () -> Complex

  # Returns zero.
  def imag: () -> Numeric

  # Returns zero.
  def imaginary: () -> Numeric

  # Returns `true` if `num` is an
  # [Integer](https://ruby-doc.org/core-2.6.3/Integer.html).
  # 
  # ```ruby
  # 1.0.integer?   #=> false
  # 1.integer?     #=> true
  # ```
  def integer?: () -> bool

  # Returns the absolute value of `num` .
  # 
  # ```ruby
  # 12.abs         #=> 12
  # (-34.56).abs   #=> 34.56
  # -34.56.abs     #=> 34.56
  # ```
  # 
  # [\#magnitude](Numeric.downloaded.ruby_doc#method-i-magnitude) is an
  # alias for [\#abs](Numeric.downloaded.ruby_doc#method-i-abs).
  def magnitude: () -> Numeric

  def modulo: (Numeric arg0) -> (Integer | Float | Rational | BigDecimal)

  # Returns `self` if `num` is not zero, `nil` otherwise.
  # 
  # This behavior is useful when chaining comparisons:
  # 
  # ```ruby
  # a = %w( z Bb bB bb BB a aA Aa AA A )
  # b = a.sort {|a,b| (a.downcase <=> b.downcase).nonzero? || a <=> b }
  # b   #=> ["A", "a", "AA", "Aa", "aA", "BB", "Bb", "bB", "bb", "z"]
  # ```
  def nonzero?: () -> self?

  # Returns the numerator.
  def numerator: () -> Integer

  # Returns 0 if the value is positive, pi otherwise.
  def phase: () -> Numeric

  # Returns an array; \[num.abs, num.arg\].
  def polar: () -> [ Numeric, Numeric ]

  def quo: (Numeric arg0) -> Numeric

  # Returns self.
  def real: () -> Numeric

  # Returns `true` if `num` is a real number (i.e. not
  # [Complex](https://ruby-doc.org/core-2.6.3/Complex.html) ).
  def real?: () -> Numeric

  # Returns an array; \[num, 0\].
  def rect: () -> [ Numeric, Numeric ]

  # Returns an array; \[num, 0\].
  def rectangular: () -> [ Numeric, Numeric ]

  def remainder: (Numeric arg0) -> (Integer | Float | Rational | BigDecimal)

  def round: (Numeric arg0) -> Numeric

  def singleton_method_added: (Symbol arg0) -> TypeError

  def step: (?Numeric? limit, ?Numeric step) { (Numeric arg0) -> any } -> Numeric
          | (?Numeric? limit, ?Numeric step) -> T::Enumerator[Numeric]

  # Returns the value as a complex.
  def to_c: () -> Complex

  def to_f: () -> Float

  def to_i: () -> Integer

  # Invokes the child class’s `to_i` method to convert `num` to an integer.
  # 
  # ```ruby
  # 1.0.class          #=> Float
  # 1.0.to_int.class   #=> Integer
  # 1.0.to_i.class     #=> Integer
  # ```
  def to_int: () -> Integer

  # Returns `num` truncated (toward zero) to a precision of `ndigits`
  # decimal digits (default: 0).
  # 
  # [Numeric](Numeric.downloaded.ruby_doc) implements this by converting its
  # value to a [Float](https://ruby-doc.org/core-2.6.3/Float.html) and
  # invoking
  # [Float\#truncate](https://ruby-doc.org/core-2.6.3/Float.html#method-i-truncate)
  # .
  def truncate: () -> Integer

  # Returns `true` if `num` has a zero value.
  def zero?: () -> bool
end
