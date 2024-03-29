require "test_helper"
require "open3"

class RBS::VendorerTest < Test::Unit::TestCase
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
      loader.add(library: "pathname")

      vendorer = Vendorer.new(vendor_dir: vendor_dir, loader: loader)

      vendorer.copy!

      assert_predicate vendor_dir, :directory?
      assert_predicate vendor_dir + "pathname-0", :directory?
      assert_predicate vendor_dir + "pathname-0/pathname.rbs", :file?
    end
  end
end
