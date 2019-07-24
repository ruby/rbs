class BasicObject
  def initialize: -> void
  def !: () -> bool
  def `!=`: (any) -> bool
  def __id__: -> Integer
  def __send__: (*any) -> any
  def equal?: (any) -> bool
  def instance_eval: (String, ?String filename, ?Integer lineno) -> any
                   | [X] { (self) -> X } -> X
  def instance_exec: [X] (*any) { (*any) -> X } -> X

  private

  def method_missing: (Symbol, *any) -> any
  def singleton_method_added: (Symbol) -> void
  def singleton_method_removed: (Symbol) -> void
  def singleton_method_undefined: (Symbol) -> void
end
