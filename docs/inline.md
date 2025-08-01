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

### Inheritance

Class declarations can have a super class.

```ruby
class UsersController < ApplicationController
end
```

The super class specification must be a constant.

The super class specification allows type applications.

```ruby
class StringArray < Array #[String]
end
```

### Current Limitations

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

## Method Definitions

Inline RBS supports methods defined using the `def` syntax in Ruby.

```ruby
class Calculator
  def add(x, y) = x+y
end
```

It detects method definitions and allows you to add annotation comments to describe their types.

### Unannotated method definition

Methods defined with `def` syntax are detected, but they are untyped.

```ruby
class Calculator
  def add(x, y) = x+y
end
```

The type of the `Calculator#add` method is `(?) -> untyped` -- it accepts any arguments without type checking and returns an `untyped` object.

### Method type annotation syntax

You can define the type of the method using `@rbs` and `:` syntax.

```ruby
class Calculator
  # @rbs (Integer, Integer) -> Integer
  def add(x, y) = x + y

  #: (Integer, Integer) -> Integer
  def subtract(x, y) = x - y
end
```

The type of both methods is `(Integer, Integer) -> Integer` -- they take two `Integer` objects and return an `Integer` object.

Both syntaxes support method overloading:

```ruby
class Calculator
  # @rbs (Integer, Integer) -> Integer
  #    | (Float, Float) -> Float
  def add(x, y) = x + y

  #: (Integer, Integer) -> Integer
  #: (Float, Float) -> Float
  def subtract(x, y) = x - y
end
```

The type of both methods is `(Integer, Integer) -> Integer | (Float, Float) -> Float`.

> [!NOTE]
> The `@rbs METHOD-TYPE` syntax allows overloads with the `|` operator, just like in RBS files.
> Multiple `: METHOD-TYPE` declarations are required for overloads.

#### Doc-style syntax

The `@rbs return: T` syntax declares the return type of a method:

```ruby
class Calculator
  # @rbs return: String
  def to_s
    "Calculator"
  end
end
```

### Current Limitations

- Class methods and singleton methods are not supported
- Parameter types are not supported with doc-style syntax
- Method visibility declaration is not supported yet

## Attributes

Inline RBS supports Ruby's attribute methods: `attr_reader`, `attr_writer`, and `attr_accessor`.

```ruby
class Person
  attr_reader :name #: String
  attr_writer :age #: Integer
  attr_accessor :email #: String?
end
```

It detects these attribute declarations and generates the corresponding getter and setter methods.

The accessor methods and instance variables are defined.

### Unannotated attributes

Attributes defined without type annotations are treated as `untyped`:

```ruby
class Person
  attr_reader :name
  attr_writer :age
  attr_accessor :email
end
```

### Type annotations for attributes

You can add type annotations to attributes using the `#:` syntax in trailing comments:

```ruby
class Person
  attr_reader :name #: String
  attr_writer :age #: Integer
  attr_accessor :email #: String?
end
```

This generates the following typed methods:
- `name: () -> String`
- `age=: (Integer) -> Integer`
- `email: () -> String?` and `email=: (String?) -> String?`

### Multiple attributes

When declaring multiple attributes in one line, the type annotation applies to all attributes:

```ruby
class Person
  attr_reader :first_name, :last_name #: String
  attr_accessor :age, :height #: Integer
end
```

All attributes in each declaration share the same type.

### Non-symbol attribute names

Attribute names must be symbol literals.

```ruby
class Person
  attr_reader "name" #: String

  age = :age
  attr_writer age #: Integer
end
```

The attribute definitions are ignored because the names are given by string literals and local variables.

### Current Limitations

- Attribute visibility is not supported yet. All attributes are _public_

## Mixin

Inline RBS supports Ruby's mixin methods: `include`, `extend`, and `prepend`.

```ruby
module Printable
  # @rbs () -> String
  def to_print
    to_s
  end
end

class Document
  include Printable
  extend Enumerable #[String]
  prepend Trackable
end
```

It detects these mixin declarations and adds them to the class or module definition.

### Basic mixin usage

Mixins work just like in regular RBS files:

```ruby
module Helper
end

class MyClass
  include Helper
  extend Helper
  prepend Helper
end
```

### Type arguments for generic modules

You can specify type arguments for generic modules using the `#[...]` syntax:

```ruby
class TodoList
  include Enumerable #[String]

  # @rbs () { (String) -> void } -> void
  def each(&block)
    @items.each(&block)
  end
end
```

### Module name requirements

Only constant module names are supported. Dynamic module references are not allowed:

```ruby
class MyClass
  include Helper         # ✓ Works - constant name

  mod = Helper
  include mod           # ✗ Ignored - non-constant module reference

  include Helper.new    # ✗ Ignored - not a simple constant
end
```

### Module name resolution

The module name resolution is based on the nesting of the class/module definitions, unlike Ruby.

Modules accessible through ancestors (super-class/included modules) are not supported.

### Current Limitations

- Only single module arguments are supported (no `include A, B` syntax)
- Module names must be constants
