# Stdlib Signatures Guide

This is a guide for contributing to `ruby-signature` by writing/revising stdlib signatures.

## Signatures

Signatures for standard libraries are located in `stdlib` directory. `stdlib/builtin` is for builtin libraries. Other libraries have directories like `stdlibt/set` or `stdlib/pathname`.

To write signatures see [syntax guide](syntax.md).

## Testing

We support writing tests for stdlib signatures.

### Writing tests

Put the test scripts in `test/stdlib` directory with `[class_name]_test.rb`, like `String_test.rb` and `File_test.rb`.
The test scripts would look like the following:

```rb
class StringTest < StdlibTest
  target String
  using hook.refinement

  def test_gsub
    s = "string"
    s.gsub(/./, "")
    s.gsub("a", "b")
    s.gsub(/./) {|x| "" }
    s.gsub(/./, {"foo" => "bar"})
    s.gsub(/./)
    s.gsub("")
  end
end
```

You need two method calls, `target` and `using`.
`target` method call tells which class is the subject of the class.
`using hook.refinement` installs a special instrumentation for stdlib, based on refinements.
And you write the sample programs which calls all of the patterns of overloads.

Note that the instrumentation is based on refinmenets and you need to write all method calls in the unit class definitions.
If the execution of the program escape from the class definition, the instrumentation is disabled and no check will be done.

### Running tests

You can run the test with:

```
$ bundle exec ruby bin/test_runner.rb              # Run all tests
$ bundle exec ruby bin/test_runner.rb String Hash  # Run specific tests
```
