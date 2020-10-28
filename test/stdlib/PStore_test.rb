require_relative "test_helper"
require "pstore"

class PStoreSingletonTest < Minitest::Test
  include TypeAssertions
  library "pstore"
  testing "singleton(::PStore)"

  def test_initialize
    assert_send_type  "(untyped file, ?bool thread_safe) -> PStore",
                      PStore, :new, "file_name", false
  end
end
