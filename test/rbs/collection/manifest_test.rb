require "test_helper"

class RBS::Collection::ManifestTest < Test::Unit::TestCase
  include RBS::Collection

  def test_from
    manifest = Manifest.from(
      Pathname("foo/0/manifest.yaml"),
      {
        "dependencies" => [
          { "name" => "set" },
          { "name" => "json" }
        ]
      }
    )

    assert_equal Pathname("foo/0/manifest.yaml"), manifest.path
    assert_equal [Manifest::Dependency.new(name: "set"), Manifest::Dependency.new(name: "json")], manifest.dependencies
  end

  def test_default
    assert_equal [], Manifest.default.dependencies
    assert_raises(RuntimeError) { Manifest.default.path }
  end
end
