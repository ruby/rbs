# Testing Core API and Standard Library Types

This is a guide for testing core/stdlib types.

## Add Tests

We support writing tests for core/stdlib signatures.

### Setup

To prepare, execute the following command.

```
$ bundle exec rake compile:rbs_extension
```

### Writing tests

First, execute `generate:stdlib_test` rake task with a class name that you want to test.

```console
$ bundle exec rake 'generate:stdlib_test[String]'
Created: test/stdlib/String_test.rb
```

Core signatures are loaded by default. To generate a test for a class defined in standard library signatures,
pass the paths containing those signatures and their dependencies after the class name.

```console
$ bundle exec rake 'generate:stdlib_test[CSV::Row,stdlib/csv/0,stdlib/forwardable/0]'
Created: test/stdlib/CSV_Row_test.rb
```

It generates `test/stdlib/[class_name]_test.rb`.
The test scripts would look like the following:

```rb
class StringSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::String)"

  def test_initialize
    assert_send_type "() -> String",
                     String, :new
    assert_send_type "(String) -> String",
                     String, :new, ""
    assert_send_type "(String, encoding: Encoding) -> String",
                     String, :new, "", encoding: Encoding::ASCII_8BIT
    assert_send_type "(String, encoding: Encoding, capacity: Integer) -> String",
                     String, :new, "", encoding: Encoding::ASCII_8BIT, capacity: 123
    assert_send_type "(encoding: Encoding, capacity: Integer) -> String",
                     String, :new, encoding: Encoding::ASCII_8BIT, capacity: 123
    assert_send_type "(ToStr) -> String",
                     String, :new, ToStr.new("")
    assert_send_type "(encoding: ToStr) -> String",
                     String, :new, encoding: ToStr.new('Shift_JIS')
    assert_send_type "(capacity: ToInt) -> String",
                     String, :new, capacity: ToInt.new(123)
  end
end

class StringTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::String"

  def test_gsub
    assert_send_type "(Regexp, String) -> String",
                     "string", :gsub, /./, ""
    assert_send_type "(String, String) -> String",
                     "string", :gsub, "a", "b"
    assert_send_type "(Regexp) { (String) -> String } -> String",
                     "string", :gsub, /./ do |x| "" end
    assert_send_type "(Regexp) { (String) -> ToS } -> String",
                     "string", :gsub, /./ do |x| ToS.new("") end
    assert_send_type "(Regexp, Hash[String, String]) -> String",
                     "string", :gsub, /./, {"foo" => "bar"}
    assert_send_type "(Regexp) -> Enumerator[String, self]",
                     "string", :gsub, /./
    assert_send_type "(String) -> Enumerator[String, self]",
                     "string", :gsub, ""
    assert_send_type "(ToStr, ToStr) -> String",
                     "string", :gsub, ToStr.new("a"), ToStr.new("b")
  end
end
```

You need include `TypeAssertions` which provide useful methods for you.
`testing` method call tells which class is the subject of the class.
You may need `library` call to test a library if the type definition is provided as a library (under `stdlib` dir).

Note that the instrumentation is based on refinements and you need to write all method calls in the unit class definitions.
If the execution of the program escape from the class definition, the instrumentation is disabled and no check will be done.

#### 📣 Method type assertions

`assert_send_type` method call asserts to be valid types and confirms to be able to execute without exceptions.
And you write the sample programs which calls all of the patterns of overloads.

We recommend write method types as _simple_ as possible inside the assertion.
It's not very easy to define _simple_, but we try to explain it with a few examples.

* Instead of `(String | Integer) -> Symbol?`, use `(String) -> Symbol` or `(Integer) -> nil`, because we know the exact argument type we are passing in the test
* Instead of `self`, `instance`, or `class`, use concrete types like `String`, `singleton(IO)`, because we know the exact type of the receiver
* Sometimes, you need union types if the method is nondeterministic -- `() -> (Integer | String)` for `[1, ""].sample` (But you can rewrite the test code as `[1].sample` instead)
* Sometimes, you need union types for heterogeneous collections -- `() { (Integer | String) -> String } -> Array[String | Integer]` for `[1, "2"].each {|i| i.to_s }` (But you can rewrite the test code as `[1, 2].each {|i| i.to_s }`)
* Using `void` is allowed if the RBS definition is `void`

Generally _simple_ means:

* The type doesn't contain `self`, `instance`, `class`, `top`, `bot`, and `untyped`
* The type doesn't contain unions and optionals

Use them if you cannot write the test without them.

One clear exception to using _simple_ types is when you use `with_int` or family helpers, that yield values with each case of the given union:

```ruby
def test_something
  with_int(3) do |int|
    # Yields twice with `Integer` and `ToInt`
    assert_send_type(
      "(int) -> Integer",
      some, :test, int
    )
  end
end
```

It's clear having type aliases makes sense.

#### 📣 Constant type assertions

Use `assert_const_type` to test that a constant matches its RBS definition.

```ruby
class FloatConstantTest < Test::Unit::TestCase
  include TypeAssertions

  def test_infinity
    assert_const_type "Float", "Float::INFINITY"
  end
end
```

It confirms:

1. The constant `Float::INFINITY` is a `Float` at runtime.
2. The type matches its RBS definition.

When testing class and exception constants, assert that their type is `"Class"`:

* **Good:** `assert_const_type "Class", "StringScanner::Error"`
* **Bad:** `assert_const_type "singleton(::StringScanner::Error)", "StringScanner::Error"`

You can place constant tests inside existing `*SingletonTest` or `*InstanceTest` classes, or define a `*ConstantTest` class.

#### 📣 Write Type Tests, Not Behavior Tests

Stdlib tests verify that RBS signatures match runtime method types. Do not test Ruby implementation behavior.

* **Use `assert_send_type` and `assert_const_type`**: Verify arguments, return values, and constants through type assertions.
* **Skip behavior assertions**: Drop `assert_equal`, `assert_instance_of`, and `assert` for return values, superclasses, and constant contents:
  * **Bad:** `assert_equal StandardError, StringScanner::Error.superclass`
  * **Bad:** `assert_equal "A", Random::Formatter::ALPHANUMERIC.first`
  * **Good:** `assert_const_type "Array[String]", "Random::Formatter::ALPHANUMERIC"`
  Reserve `assert_equal` and `assert` for test setup.
* **Ignore untestable behavior**: If a method behavior has no corresponding type check (such as `Singleton.instance` object identity), test only the method signature and return type.

#### 📣 Extending Existing Tests

When updating existing library tests:

1. **Check existing tests first**: Open `test/stdlib/<Library>_test.rb`.
2. **Add to existing test classes**: Put new tests in `*InstanceTest`, `*SingletonTest`, or `*ConstantTest`. Do not create duplicate test classes.
3. **Preserve existing coverage**: Keep existing test cases intact.

### Running tests

You can run the test with:

```console
$ bundle exec rake stdlib_test                # Run all tests
$ bundle exec ruby test/stdlib/String_test.rb # Run specific tests
```
