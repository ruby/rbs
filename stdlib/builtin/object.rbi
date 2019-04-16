class Object < BasicObject
  include Kernel
  def tap: { (self) -> void } -> self
  def to_s: -> String
  def hash: -> Integer
  def eql?: (any) -> bool
  def `==`: (any) -> bool
  def `===`: (any) -> bool
  def `!=`: (any) -> bool
  def class: -> class
  def is_a?: (Module) -> bool
  def inspect: -> String
  def freeze: -> self
  def method: (Symbol) -> Method
  def yield_self: [X] { (self) -> X } -> X
  def dup: -> self
  def send: (Symbol, *any) -> any
  def __send__: (Symbol, *any) -> any
  def instance_variable_get: (Symbol) -> any
  def nil?: -> bool
  def `!`: -> bool
  def Array: (any) -> Array[any]
  def Hash: (any) -> Hash[any, any]
  def instance_eval: [X] { (self) -> X } -> X
                   | (String, ?String, ?Integer) -> any
  def define_singleton_method: (Symbol | String, any) -> Symbol
                             | (Symbol) { (*any) -> any } -> Symbol
end
