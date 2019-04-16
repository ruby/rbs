class MatchData
  def `[]`: (Integer | String | Symbol) -> String?
          | (Integer, Integer) -> Array[String]
          | (Range[Integer]) -> Array[String]
  def begin: (Integer) -> Integer?
           | (String | Symbol) -> Integer
  def captures: -> Array[String]
  def end: (Integer | String | Symbol) -> Integer
  def length: -> Integer
  def named_captures: -> Hash[String, String?]
  def names: -> Array[String]
  def offset: (Integer | String | Symbol) -> [Integer, Integer]
  def post_match: -> String
  def pre_match: -> String
  def regexp: -> Regexp
  def size: -> Integer
  def string: -> String
  def to_a: -> Array[String]
  def values_at: (*(Integer | String | Symbol)) -> Array[String?]
end
