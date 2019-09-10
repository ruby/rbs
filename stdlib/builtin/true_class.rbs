# The global value `true` is the only instance of class `TrueClass` and
# represents a logically true value in boolean expressions. The class
# provides operators allowing `true` to be used in logical expressions.
class TrueClass
  # And—Returns `false` if *obj* is `nil` or `false`, `true` otherwise.
  def &: (any obj) -> bool

  # Exclusive Or—Returns `true` if *obj* is `nil` or `false`, `false`
  # otherwise.
  def ^: (any obj) -> bool

  # Or—Returns `true` . As *obj* is an argument to a method call, it is
  # always evaluated; there is no short-circuit evaluation in this case.
  # 
  # ```ruby
  # true |  puts("or")
  # true || puts("logical or")
  # ```
  # 
  # *produces:*
  # 
  # ```
  # or
  # ```
  def |: (any obj) -> TrueClass

  def !: () -> FalseClass
end
