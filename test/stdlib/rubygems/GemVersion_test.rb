require_relative "../test_helper"

class GemVersionSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Gem::Version)"

  def test_correct?
    assert_send_type  "(String) -> bool",
                      Gem::Version, :correct?, "1.2.3"
    assert_send_type  "(_ToS) -> bool",
                      Gem::Version, :correct?, ToS.new.__with_object_methods(:respond_to?, :nil?)
  end

  def test_create
    assert_send_type  "(String) -> Gem::Version",
                      Gem::Version, :create, "1.2.3"
    assert_send_type  "(_ToS) -> Gem::Version",
                      Gem::Version, :create, ToS.new("1.2.3").__with_object_methods(:respond_to?, :hash, :nil?, :is_a?)
    assert_send_type  "(Gem::Version) -> Gem::Version",
                      Gem::Version, :create, Gem::Version.new("1.2.3")
  end

  def test_new
    assert_send_type  "(String) -> Gem::Version",
                      Gem::Version, :new, "1.2.3"
    assert_send_type  "(_ToS) -> Gem::Version",
                      Gem::Version, :new, ToS.new("1.2.3").__with_object_methods(:respond_to?, :hash, :nil?, :is_a?)
  end
end

class GemVersionInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Gem::Version"

  def test_comparable
    assert_send_type  "(Gem::Version) -> Integer",
                      Gem::Version.new("0.0.1"), :<=>, Gem::Version.new("1.0.0")
    assert_send_type  "(String) -> (nil | Integer)",
                      Gem::Version.new("0.0.0"), :<=>, "1.0.0"
    assert_send_type  "(String) -> (nil | Integer)",
                      Gem::Version.new("0.0.0"), :<=>, "not a version"
  end

  def test_approximate_recommendation
    assert_send_type  "() -> String",
                      Gem::Version.new("0.0.1"), :approximate_recommendation
  end

  def test_bump
    assert_send_type  "() -> Gem::Version",
                      Gem::Version.new("0.0.1"), :bump
  end

  def test_canonical_segments
    assert_send_type  "() -> Array[Integer]",
                      Gem::Version.new("0.0.1"), :canonical_segments
    assert_send_type  "() -> Array[Integer | String]",
                      Gem::Version.new("0.0.1-alpha.1"), :canonical_segments
  end

  def test_eql?
    assert_send_type  "(Gem::Version) -> bool",
                      Gem::Version.new("0.0.1"), :eql?, Gem::Version.new("0.0.1")
    assert_send_type  "(String) -> bool",
                      Gem::Version.new("0.0.1"), :eql?, "1.0.0"
  end

  def test_marshal_dump
    assert_send_type  "() -> Array[String]",
                      Gem::Version.new("0.0.1"), :marshal_dump
  end

  def test_marshal_load
    assert_send_type  "(Array[String]) -> void",
                      Gem::Version.new("0.0.1"), :marshal_load, ["1.0.0"]
  end

  def test_prerelease?
    assert_send_type  "() -> bool",
                      Gem::Version.new("0.0.1"), :prerelease?
  end

  def test_release
    assert_send_type  "() -> Gem::Version",
                      Gem::Version.new("1.0.0.a"), :release
  end

  def test_version
    assert_send_type  "() -> String",
                      Gem::Version.new("1.0.0"), :version
  end
end
