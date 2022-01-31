require_relative "test_helper"
require "nkf"

class NKFSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "nkf"
  testing "singleton(::NKF)"


  def test_guess
    assert_send_type  "(::String str) -> ::Encoding",
                      NKF, :guess, "str"
  end

  def test_nkf
    assert_send_type  "(::String opt, ::String str) -> ::String",
                      NKF, :nkf, "-w", "str"
  end
end
