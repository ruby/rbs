require_relative "../test_helper"

class GemRequirementSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Gem::Requirement)"

  def test_create
    assert_send_type  "() -> Gem::Requirement",
                      Gem::Requirement, :create
    assert_send_type  "(String, Gem::Version, Gem::Requirement, nil) -> Gem::Requirement",
                      Gem::Requirement, :create, "1.0", Gem::Version.new("1.2"), Gem::Requirement.new, nil
    assert_send_type  "(nil) -> Gem::Requirement",
                      Gem::Requirement, :create, nil
  end

  def test_default
    assert_send_type  "() -> Gem::Requirement",
                      Gem::Requirement, :default
  end

  def test_default_prerelease
    assert_send_type  "() -> Gem::Requirement",
                      Gem::Requirement, :default_prerelease
  end

  def test_parse
    assert_send_type  "(String) -> [ String, Gem::Version ]",
                      Gem::Requirement, :parse, "1.0"
    assert_send_type  "(Gem::Version) -> [ String, Gem::Version ]",
                      Gem::Requirement, :parse, Gem::Version.new("1.0")
  end

  def test_new
    assert_send_type  "() -> Gem::Requirement",
                      Gem::Requirement, :new
    assert_send_type  "(String, Gem::Version) -> Gem::Requirement",
                      Gem::Requirement, :new, "1.0", Gem::Version.new("1.2")
  end
end

class GemRequirementInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Gem::Requirement"

  def test_concat
    assert_send_type  "(Array[String | Gem::Version]) -> void",
                      Gem::Requirement.new, :concat, ["1.0", Gem::Version.new("1.1")]
  end

  def test_exact?
    assert_send_type  "() -> bool",
                      Gem::Requirement.new, :exact?
  end

  def test_none?
    assert_send_type  "() -> bool",
                      Gem::Requirement.new, :none?
  end

  def test_prerelease?
    assert_send_type  "() -> bool",
                      Gem::Requirement.new, :prerelease?
  end

  def test_satisfied_by?
    assert_send_type  "(Gem::Version) -> bool",
                      Gem::Requirement.new, :satisfied_by?, Gem::Version.new("1.0")

    # alias
    assert_send_type  "(Gem::Version) -> bool",
                      Gem::Requirement.new, :===, Gem::Version.new("1.0")
    assert_send_type  "(Gem::Version) -> bool",
                      Gem::Requirement.new, :=~, Gem::Version.new("1.0")
  end

  def test_specific?
    assert_send_type  "() -> bool",
                      Gem::Requirement.new, :specific?
  end
end
