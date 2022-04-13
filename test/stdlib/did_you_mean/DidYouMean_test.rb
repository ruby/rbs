require_relative "../test_helper"

class DidYouMean::CorrectableTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::Correctable"

  def test_corrections
    c = Class.new.include(DidYouMean::Correctable)
    assert_send_type  "() -> ::Array[::String]",
                      c.new, :corrections
  end
end

class DidYouMean::FormatterSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::Formatter)"

  def test_message_for
    assert_send_type  "(::Array[::String] corrections) -> ::String",
                      DidYouMean::Formatter, :message_for, ['foo', 'bar', 'baz']
  end
end

class DidYouMean::JaroSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::Jaro)"

  def test_distance
    assert_send_type  "(::String, ::String) -> ::Integer",
                      DidYouMean::Jaro, :distance, "foo", "bar"
  end
end

class DidYouMean::JaroTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::Jaro"

  def test_distance
    c = Class.new.include(DidYouMean::Jaro)
    assert_send_type  "(::String, ::String) -> ::Integer",
                      c.new, :distance, "foo", "bar"
  end
end

class DidYouMean::JaroWinklerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::JaroWinkler)"

  def test_distance
    assert_send_type  "(::String, ::String) -> ::Integer",
                      DidYouMean::JaroWinkler, :distance, "foo", "bar"
  end
end

class DidYouMean::JaroWinklerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::JaroWinkler"

  def test_distance
    c = Class.new.include(DidYouMean::JaroWinkler)
    assert_send_type  "(::String, ::String) -> ::Integer",
                      c.new, :distance, "foo", "bar"
  end
end

class DidYouMean::KeyErrorCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::KeyErrorChecker)"

  def test_initialize
    assert_send_type  "(::KeyError[Symbol, Hash[Symbol, Integer]]) -> void",
                      DidYouMean::KeyErrorChecker, :new, KeyError.new(key: :a, receiver: { b: 1 })
  end
end

class DidYouMean::KeyErrorCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::KeyErrorChecker"

  def test_corrections
    assert_send_type  "() -> ::Array[::String]",
                      DidYouMean::KeyErrorChecker.new(KeyError.new(key: :a, receiver: { b: 1 })), :corrections
  end
end

class DidYouMean::LevenshteinSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::Levenshtein)"

  def test_distance
    assert_send_type  "(::String, ::String) -> ::Integer?",
                      DidYouMean::Levenshtein, :distance, "foo", "bar"
  end
end

class DidYouMean::LevenshteinTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::Levenshtein"

  def test_distance
    c = Class.new.include(DidYouMean::Levenshtein)
    assert_send_type  "(::String, ::String) -> ::Integer?",
                      c.new, :distance, "foo", "bar"
  end
end

class DidYouMean::MethodNameCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::MethodNameChecker)"

  def test_new
    assert_send_type  "(::NoMethodError[nil]) -> ::DidYouMean::MethodNameChecker",
                      DidYouMean::MethodNameChecker, :new, NoMethodError.new(receiver: nil)
  end
end

class DidYouMean::MethodNameCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::MethodNameChecker"

  def test_corrections
    assert_send_type  "() -> ::Array[::Symbol]",
    DidYouMean::MethodNameChecker.new(NoMethodError.new("error", :object, receiver: Object.new)), :corrections
  end
end

class DidYouMean::NullCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::NullChecker)"

  def test_new
    assert_send_type  "(*untyped) -> ::DidYouMean::NullChecker",
                      DidYouMean::NullChecker, :new
  end
end

class DidYouMean::NullCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::NullChecker"

  def test_corrections
    assert_send_type  "() -> ::Array[untyped]",
                      DidYouMean::NullChecker.new, :corrections
  end
end

class DidYouMean::PatternKeyNameCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::PatternKeyNameChecker)"

  def test_new
    mock = Struct.new(:key, :matchee).new(:foo, { fooo: 1 })
    assert_send_type  "(untyped) -> ::DidYouMean::PatternKeyNameChecker",
                      DidYouMean::PatternKeyNameChecker, :new, mock
  end
end

class DidYouMean::PatternKeyNameCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::PatternKeyNameChecker"

  def test_corrections
    mock = Struct.new(:key, :matchee).new(:foo, { fooo: 1 })
    assert_send_type  "() -> ::Array[::String]",
                      DidYouMean::PatternKeyNameChecker.new(mock), :corrections
  end
end

class DidYouMean::RequirePathCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::RequirePathChecker)"

  def test_new
    mock = Struct.new(:path).new("did_you_meen")
    assert_send_type  "(untyped exception) -> ::DidYouMean::RequirePathChecker",
                      DidYouMean::RequirePathChecker, :new, mock
  end

  def test_requireables
    assert_send_type  "() -> ::Array[::String]",
                      DidYouMean::RequirePathChecker, :requireables
  end
end

class DidYouMean::RequirePathCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::RequirePathChecker"

  def test_corrections
    mock = Struct.new(:path).new("did_you_meen")
    assert_send_type  "() -> ::Array[::String]",
                      DidYouMean::RequirePathChecker.new(mock), :corrections
  end
end

class DidYouMean::SpellCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::SpellChecker)"

  def test_new
    assert_send_type  "(dictionary: ::Array[::String | ::Symbol]) -> ::DidYouMean::SpellChecker",
                      DidYouMean::SpellChecker, :new, dictionary: ["foo"]
  end
end

class DidYouMean::SpellCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::SpellChecker"

  def test_correct
    assert_send_type  "(::String | ::Symbol input) -> ::Array[::String]",
                      DidYouMean::SpellChecker.new(dictionary: ["foo"]), :correct, "fooo"
  end
end

class DidYouMean::TreeSpellCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::TreeSpellChecker)"

  def test_new
    assert_send_type  "(dictionary: ::Array[::String], ?separator: ::String, ?augment: bool?) -> ::DidYouMean::TreeSpellChecker",
                      DidYouMean::TreeSpellChecker, :new, dictionary: ["foo/bar"]
  end
end

class DidYouMean::TreeSpellCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::TreeSpellChecker"

  def test_correct
    assert_send_type  "(::String input) -> ::Array[::String]",
                      DidYouMean::TreeSpellChecker.new(dictionary: ["foo/bar"]), :correct, "foo/baz"
  end
end

class DidYouMean::VariableNameCheckerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "singleton(::DidYouMean::VariableNameChecker)"

  def test_new
    assert_send_type  "(NameError[untyped]) -> void",
                      DidYouMean::VariableNameChecker, :new, NameError.new(receiver: Object.new)
  end
end

class DidYouMean::VariableNameCheckerTest < Test::Unit::TestCase
  include TypeAssertions

  library "did_you_mean"
  testing "::DidYouMean::VariableNameChecker"

  def test_corrections
    mock = Struct.new(:name, :receiver).new(:object, Object.new)
    assert_send_type  "() -> ::Array[::Symbol]",
                      DidYouMean::VariableNameChecker.new(mock), :corrections
  end
end
