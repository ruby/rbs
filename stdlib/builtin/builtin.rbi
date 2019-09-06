interface _ToI
  def to_i: -> Integer
end

interface _ToInt
  def to_int: -> Integer
end

interface _ToS
  def to_s: -> String
end

interface _Each[A, B]
  def each: { (A) -> void } -> B
end

class BigDecimal
end
