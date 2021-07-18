require_relative "test_helper"
require "dbm"

class DBMSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "dbm"
  testing "singleton(::DBM)"

  def test_open
    path = "test/assets/dbm/"
    FileUtils.mkdir_p(path)

    assert_send_type "(*untyped) -> ::DBM ",
                     ::DBM,
                     :open, "#{path}.test_open", 0666, ::DBM::WRCREAT

    FileUtils.remove_dir(path)
  end
end

class DBMTest < Test::Unit::TestCase
  include TypeAssertions
  library "dbm"
  testing "::DBM"

  def setup
    super
    path = "test/assets/dbm/"
    FileUtils.mkdir_p(path) unless File.exist?(path)
    @dbm = ::DBM.open("test/assets/dbm/sample", 0666, ::DBM::WRCREAT)
    @dbm["setup"] = "Value"
  end

  def teardown
    super
    path = "test/assets/dbm/sample.db"
    File.delete(path) if File.exist?(path)
  end

  def test_clear
    assert_send_type "() -> self", @dbm, :clear
  end

  def test_closed?
    assert_send_type "() -> bool", @dbm, :closed?
  end

  def test_each
    assert_send_type "(?untyped, ?untyped) -> Enumerator[untyped, ::DBM]", @dbm, :each
  end

  def test_each_key
    assert_send_type "(?untyped, ?untyped) -> Enumerator[untyped, ::DBM]", @dbm, :each_key
  end

  def test_each_pair
    assert_send_type "(?untyped, ?untyped) -> Enumerator[untyped, ::DBM]", @dbm, :each_pair
  end

  def test_update
    assert_send_type "(untyped) -> ::DBM", @dbm, :update, { "my_key": 14 }
  end

  def test_values_at
    @dbm["key1"] = 1
    @dbm["key2"] = 2

    assert_send_type "(*String) -> Array[untyped]", @dbm, :values_at, "key1", "key2"
  end

  def test_to_a
    assert_send_type "() -> Array[untyped]", @dbm, :to_a
  end

  def test_to_hash
    assert_send_type "() -> Hash[String, untyped]", @dbm, :to_hash
  end

  def test_invert
    assert_send_type "() -> Hash[untyped, String]", @dbm, :invert
  end

  def test_key
    @dbm["key_key"] = 1
    assert_send_type "(untyped) -> (String | NilClass)", @dbm, :key, "key_key"
    assert_send_type "(untyped) -> (String | NilClass)", @dbm, :key, "keaaaay1"
  end

  def test_replace
    @dbm["key4"] = 1
    assert_send_type "(untyped) -> ::DBM", @dbm, :replace, { "key4": 55 }
  end

  def test_shift
    @dbm["key5"] = 1
    assert_send_type "() -> Array[untyped]", @dbm, :shift
  end

  def test_store
    assert_send_type(
      "(String, String) -> String",
      @dbm, :store, "keeey", "valuuueee"
    )
  end
end
