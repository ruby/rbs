module Kernel
  private
  def raise: () -> any
           | (String) -> any
           | (*any) -> any

  def block_given?: -> bool
  def enum_for: (Symbol, *any) -> any
  def require_relative: (*String) -> void
  def require: (*String) -> void
  def loop: { () -> void } -> void
  def puts: (*any) -> void
  def eval: (String, ? Integer?, ?String) -> any
  def Integer: (String, Integer) -> Integer
             | (_ToI | _ToInt) -> Integer
  def instance_of?: (Class) -> bool
  def load: (String) -> bool
end
