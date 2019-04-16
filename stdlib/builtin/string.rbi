class String
  def `[]`: (Range[Integer]) -> String
          | (Integer, Integer) -> String
  def to_sym: -> Symbol
  def `+`: (String) -> String
  def to_str: -> String
  def size: -> Integer
  def bytes: -> Array[Integer]
  def `%`: (any) -> String
  def `<<`: (String) -> self
  def chars: -> Array[String]
  def slice!: (Integer) -> String
            | (Integer, Integer) -> String
            | (String) -> String
            | (Regexp, ?Integer) -> String
            | (Range[Integer]) -> String
  def unpack: (String) -> Array[any]
  def b: -> String
  def downcase: -> String
  def split: (String) -> Array[String]
           | (Regexp) -> Array[String]
  def gsub: (Regexp, String) -> self
          | (String, String) -> self
          | (Regexp) { (String) -> _ToS } -> String
  def gsub!: (Regexp, String) -> self
           | (String, String) -> self
           | (Regexp) { (String) -> _ToS } -> String
  def sub: (Regexp | String, String) -> self
         | (Regexp | String) { (String) -> _ToS } -> String
  def chomp: -> String
           | (String) -> String
  def *: (Integer) -> String
  def scan: (Regexp) { (Array[String]) -> void } -> String
          | (Regexp) -> Array[String]
  def lines: -> Array[String]
  def bytesize: -> Integer
  def start_with?: (String) -> bool
  def byteslice: (Integer, Integer) -> String
  def empty?: -> bool
  def length: -> Integer
  def force_encoding: (any) -> self
  def to_i: -> Integer
          | (Integer) -> Integer
  def end_with?: (*String) -> bool
end
