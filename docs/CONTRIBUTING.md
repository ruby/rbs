# Core and Standard Library Signatures Contribution Guide

## Guides

* [RBS by Example](rbs_by_example.md)
* [Writing Signature Guide](sigs.md)
* [Testing Core API and Standard Library Types](stdlib.md)
* [Syntax](syntax.md)

## Introduction

The RBS repository contains the type definitions of Core API and Standard Libraries.
There are some discussions whether if it is the best to have them in this repository, but we have them and continue updating the files meanwhile.

The target version of the bundled type definitions is the [latest _release_ of Ruby](https://www.ruby-lang.org/en/downloads/branches/) -- `4.0` as of 2026.
Note, however, that the CI runs the tests on every non-EOL Ruby -- `3.3` and later as of 2026.

**The core API** type definitions are in `core` directory.
You will find the familiar class names in the directory, like `string.rbs` or `array.rbs`.

**The standard libraries** type definitions are in `stdlib` directory.
They have the [third party repository](repo.md) structure.
There is a `set` directory for the `set` library, and it contains `0` directory.
Because RBS supports the latest release of Ruby, we have one set of RBS files which corresponds to the bundled versions of the libraries.

## Steps for Contribution

1. Pick the class/library you will work for.
2. Make a directory `stdlib/foo/0` if you work for one of the standard libraries.
3. Write RBS type definitions and tests.

You will typically follow the steps as follows:

1. Run `rbs prototype runtime` to generate list of methods.
2. Run `rbs annotate` to import RDoc comments.
3. Run `rake generate:stdlib_test[CLASS,PATH,...]` to generate a test case. Pass the paths to the standard library signatures and their dependencies when needed.
4. Write the type definitions and tests.

See the next *Useful Tools* section and the guides above for writing and testing RBS files.

## Useful Tools

* `rbs prototype runtime --merge String`
  * Generate a prototype using runtime API.
  * `--merge` tells to use the method types in RBS if exists.
* `rbs prototype runtime --merge --method-owner=Numeric Integer`
  * You can use --method-owner if you want to print method of other classes too, for documentation purpose.
* `rbs annotate core/string.rbs`
  * Import RDoc comments.
  * The imported docs contain the description, *arglists*, and filenames to help writing types.
* `bin/query-rdoc String#initialize`
  * Print RDoc documents in the format you can copy-and-paste to RBS.
* `bin/sort core/string.rbs`
  * Sort declarations members in RBS files.
* `rbs -r LIB validate`
  Validate the syntax and some of the semantics.
* `rake generate:stdlib_test[String]`
  Scaffold the stdlib test.
* `rake test/stdlib/Array_test.rb`
  Run specific stdlib test with the path.

### Standard STDLIB Members Order

We define the standard members order so that ordering doesn't bother reading diffs or git-annotate outputs.

1. `def self.new` or `def initialize`
2. Mixins
3. Attributes
4. Singleton methods
5. `public` & public instance methods
6. `private` & private instance methods

```rbs
class HelloWorld[X]
  def self.new: [A] () { (void) -> A } -> HelloWorld[A]         # new or initialize comes first
  def initialize: () -> void

  include Enumerable[X, void]                                   # Mixin comes next

  attr_reader language: (:ja | :en)                             # Attributes

  def self.all_languages: () -> Array[Symbol]                   # Singleton methods

  public                                                        # Public instance methods

  def each: () { (A) -> void } -> void                          # Members are sorted dictionary order

  def to_s: (?Locale) -> String

  private                                                       # Private instance methods

  alias validate validate_locale

  def validate_locale: () -> void
end
```

## Q&A

### Some of the standard libraries are gems. Why we put the files in this repo?

You are correct. We want to move to their repos. We haven't started the migration yet.

However, bundled gems listed in `ALUMNI_STDLIBS` in `lib/rbs/collection/config/lockfile_generator.rb` (such as `abbrev`, `benchmark`, `bigdecimal`, `csv`, and `logger`) maintain their RBS definitions in their upstream repositories (e.g., `ruby/csv`). Submit type improvements for those libraries to their respective repositories instead of `ruby/rbs`.

### How can we handle incompatibilities of core APIs and standard libraries between Rubies

We ignore the incompatibilities for now.
We focus on the latest version of core APIs and standard libraries.

* **Do not use union types to bridge Ruby versions**: Avoid patterns like `URI::RFC2396_Parser | URI::RFC3986_Parser`. Match the signature to the latest supported Ruby release.

### Should we use `void` or `untyped` for method return values?

Use `void` when callers should ignore or discard the return value. Use `untyped` only when the method returns an arbitrary object intended for use. (See [syntax guide](syntax.md#void-boolish-or-top)).

### How do we avoid duplicate documentation when importing RDoc?

When an extension library extends a core class (such as `time` extending `Time` or `random-formatter` extending `Random::Formatter`), `rbs annotate` can duplicate core class documentation. Add `%a{annotate:rdoc:skip}` to the module or class declaration to skip the duplicate docs.

### Why does RBS declare methods that Ruby does not define on that class?

Some declarations describe how a method is used rather than where Ruby defines it.

* `Numeric#+` and `#-` are declared on `Numeric` so that code typed as `Numeric` can add and subtract, although only its subclasses define them.
* `Struct.members` and `.keyword_init?` are declared on `Struct`, although Ruby defines them only on the classes that `Struct.new` creates.
* A method that Ruby undefines in a subclass is declared with the `bot` return type, so that calling it is a type error. For example, `Complex#<` is declared as `def <: (Numeric) -> bot`, because `Complex` undefines the `<` inherited from `Comparable`.

`test/stdlib/method_drift_test.rb` checks that the core signatures match the runtime.
It ignores methods returning `bot`, and lists the other exceptions in `MethodDriftTest::SKIP`.
