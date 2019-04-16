class Proc
  def `[]`: (*any) -> any
  def call: (*any) -> any
  def `===`: (*any) -> any
  def yield: (*any) -> any
  def arity: -> Integer
  def binding: -> any
  def curry: -> Proc
           | (Integer) -> Proc
  def lambda?: -> bool
  def parameters: -> Array[[:req | :opt | :rest | :keyreq | :key | :keyrest | :block, Symbol]]
  def source_location: -> [String, Integer]?
  def to_proc: -> self
end
