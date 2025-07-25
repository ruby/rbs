# Inline RBS Type Declaration

Inline RBS type declarations allow you to write type annotations directly in your Ruby source files using comments. Instead of maintaining separate `.rbs` files, you can keep your type information alongside your Ruby code, making it easier to keep types and implementation in sync.

The following example defines `Calculator` class and `add` instance method. The `@rbs` comment gives the type of the `add` method with the RBS method type syntax.

```ruby
class Calculator
  # @rbs (Integer, Integer) -> Integer
  def add(a, b)
    a + b
  end
end
```
