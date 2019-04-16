class Float < Numeric
  def `*`: (Float) -> Float
         | (Integer) -> Float
         | (Numeric) -> Numeric
  def `-`: (Float) -> Float
  def `+`: (Float) -> Float
         | (Numeric) -> Numeric
  def round: (Integer) -> (Float | Integer)
           | () -> Integer
  def floor: -> Integer
  def `/`: (Float) -> Float
         | (Integer) -> Float
         | (Numeric) -> Numeric
end
