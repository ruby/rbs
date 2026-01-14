require_relative "test_helper"
require "pstore"

class PStoreSingletonTest < Test::Unit::TestCase
  include TestHelper
  library "pstore"
  testing "singleton(::PStore)"

  def test_initialize
    assert_send_type  "(path file, ?bool thread_safe) -> PStore",
                      PStore, :new, "file_name", false
    assert_send_type  "(path file, ?Symbol) -> PStore",
                      PStore, :new, "file_name", :false
    assert_send_type  "(path file, ?bool thread_safe) -> PStore[Integer]",
                      PStore, :new, "file_name", false
    assert_send_type  "(path file, ?Symbol) -> PStore[Integer, Integer]",
                      PStore, :new, "file_name", :false
  end

end

class PStoreInstanceTest < Test::Unit::TestCase
  include TestHelper
  library "pstore"
  testing "::PStore[Symbol, Integer]"

  def test_accessors
    store = PStore.new("file_name", false)
    store.transaction do |st|
      st[:foo] = 1

      assert_send_type  "(Symbol) -> Integer",
                        st, :[], :foo
      assert_send_type  "(Symbol) -> nil",
                        st, :[], :bar
    end
  end
end
