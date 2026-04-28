class ToAry
  def initialize (*x) @x = x end
  def to_ary = @x
end

class Pair
  def initialize(x, y) @x, @y = x, y end
  def to_ary = [@x, @y]
end

class Test
  def self.takes_pair(pair)
    x, y = pair.to_ary
    x + y
  end
end

is_pair = Pair.new(1, 2r) #: Pair[Integer, Rational]

Test.takes_pair(is_pair)


Hash[[
  Pair.new(:a, 1r),
  Pair.new(:b, 2r)
]] #: Hash[Symbol, Rational]

Hash[
  ToAry.new(
    Pair.new(:a, 1r),
    Pair.new(:b, 2r)
  )
] #: Hash[Symbol, Rational]

hash = { a: 3, b: 4 }
hash.to_h { |k, v| Pair.new(k.to_s, v.to_r) } #: Hash[String, Rational]

