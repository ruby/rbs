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

## Classes

Inline RBS supports class definitions from your Ruby code. When you define a class in Ruby, the library recognizes it and the corresponding class definition is generated in RBS.

```ruby
class App
end
```

The `::App` class is defined in RBS and you can use it as a type.

### Non-constant class paths

Only classes with constant names are imported. Dynamic or non-constant class definitions are ignored:

```ruby
# This class is imported
class MyClass
end

# This is ignored - dynamic class definition
MyClass = Class.new do
end

# This is also ignored - non-constant class name
object = Object
class object::MyClass
end
```

### Class Nesting

Nested classes work as expected:

```ruby
class Client
  class Error
  end
end
```

This creates the types `::Client` and `::Client::Error`.

### Current Limitations

- Inheritance is not supported
- Generic class definitions are not supported

## Modules

Inline RBS supports module definitions from your Ruby code. When you define a module in Ruby, the library recognizes it and the corresponding module definition is generated in RBS.

```ruby
module Helper
end
```

The `::Helper` module is defined in RBS and you can use it as a type.

### Non-constant module paths

Only modules with constant names are imported. Dynamic or non-constant module definitions are ignored:

```ruby
# This module is imported
module MyModule
end

# This is ignored - dynamic module definition
MyModule = Module.new do
end

# This is also ignored - non-constant module name
object = Object
module object::MyModule
end
```

### Module Nesting

Nested modules work as expected:

```ruby
module API
  module V1
    module Resources
    end
  end
end
```

This creates the types `::API`, `::API::V1`, and `::API::V1::Resources`.

### Current Limitations

- Generic module definitions are not supported
- Module self-type constraints are not supported

