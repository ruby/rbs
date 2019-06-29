interface _Exception0
  def exception: () -> any
end

interface _Exception1[T]
  def exception: (T) -> any
end

module Kernel
  private

  def raise: () -> bot
           | (String, ?cause: any) -> bot
           | (_Exception0 exception_instance, ?cause: any) -> bot
           | [T] (_Exception1[T] exception_class, T message, ?Array[String]? backtrace, ?cause: any) -> bot

  alias fail raise

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
