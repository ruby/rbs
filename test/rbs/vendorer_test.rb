require "test_helper"
require "open3"

class RBS::VendorerTest < Minitest::Test
  include TestHelper

  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  Repository = RBS::Repository
  Declarations = RBS::AST::Declarations
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  Vendorer = RBS::Vendorer

  def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end

  def test_vendor_core
    mktmpdir do |path|
      vendor_dir = path + "vendor/rbs"

      loader = EnvironmentLoader.new()
      vendorer = Vendorer.new(vendor_dir: vendor_dir, loader: loader)

      vendorer.copy!

      assert_predicate vendor_dir, :directory?
      assert_predicate vendor_dir + "core", :directory?
      assert_predicate vendor_dir + "core/object.rbs", :file?
    end
  end

  def test_vendor_library
    mktmpdir do |path|
      vendor_dir = path + "vendor/rbs"

      loader = EnvironmentLoader.new()
      loader.add(library: "set")

      vendorer = Vendorer.new(vendor_dir: vendor_dir, loader: loader)

      vendorer.copy!

      assert_predicate vendor_dir, :directory?
      assert_predicate vendor_dir + "set-0", :directory?
      assert_predicate vendor_dir + "set-0/set.rbs", :file?
    end
  end
end
