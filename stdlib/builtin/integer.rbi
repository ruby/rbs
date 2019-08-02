class Integer < Numeric
  def to_i: -> Integer
  def to_int: -> Integer
  def `+`: (Integer) -> Integer
         | (Numeric) -> Numeric
  def `^`: (Numeric) -> Integer
  def `*`: (Integer) -> Integer
         | (Float) -> Float
         | (Numeric) -> Numeric
  def `>>`: (Integer) -> Integer
  def step: (Integer, ?Integer) { (Integer) -> any } -> self
          | (Integer, ?Integer) -> Enumerator[Integer, self]
  def times: { (Integer) -> any } -> self
  def `%`: (Integer) -> Integer
  def `-`: (Integer) -> Integer
         | (Float) -> Float
         | (Numeric) -> Numeric
  def `&`: (Integer) -> Integer
  def `|`: (Integer) -> Integer
  def `[]`: (Integer) -> Integer
  def `<<`: (Integer) -> Integer
  def floor: (Integer) -> Integer
           | () -> Integer
  def divmod: (Numeric) -> [Integer, Numeric]
  def `**`: (Integer) -> Integer
  def `/`: (Integer) -> Integer
       | (Float) -> Float
       | (Numeric) -> Numeric
  def `~`: () -> Integer
end
