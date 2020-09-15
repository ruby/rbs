require "test_helper"
require "open3"

class RBS::VendorerTest < Minitest::Test
  include TestHelper

  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  Declarations = RBS::AST::Declarations
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  Vendorer = RBS::Vendorer

  def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end

  def test_vendor_stdlib
    mktmpdir do |path|
      vendor_dir = path + "vendor"
      vendorer = Vendorer.new(vendor_dir: vendor_dir)

      vendorer.stdlib!

      assert_operator vendor_dir + "stdlib/builtin", :directory?
      assert_operator vendor_dir + "stdlib/builtin/basic_object.rbs", :file?
      assert_operator vendor_dir + "stdlib/set", :directory?
      assert_operator vendor_dir + "stdlib/set/set.rbs", :file?
    end
  end

  def test_vendor_clean
    mktmpdir do |path|
      vendor_dir = path + "vendor"
      vendorer = Vendorer.new(vendor_dir: vendor_dir)

      vendorer.stdlib!

      assert_operator vendor_dir, :directory?

      vendorer.clean!

      refute_operator vendor_dir, :directory?
    end
  end

  def test_vendor_gem
    skip unless has_gem?("rbs-amber")

    mktmpdir do |path|
      vendor_dir = path + "vendor"
      vendorer = Vendorer.new(vendor_dir: vendor_dir)

      vendorer.stdlib!
      vendorer.gem! "rbs-amber", nil

      assert_operator vendor_dir + "stdlib", :directory?
      assert_operator vendor_dir + "gems/rbs-amber", :directory?
    end
  end
end
