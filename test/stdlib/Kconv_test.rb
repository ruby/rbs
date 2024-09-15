require_relative "test_helper"
require "kconv"

class KconvSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "kconv"
  testing "singleton(::Kconv)"

  def test_ASCII
    assert_const_type "::Encoding", "Kconv::ASCII"
  end

  def test_AUTO
    assert_const_type "nil", "Kconv::AUTO"
  end

  def test_BINARY
    assert_const_type "::Encoding", "Kconv::BINARY"
  end

  def test_EUC
    assert_const_type "::Encoding", "Kconv::EUC"
  end

  def test_JIS
    assert_const_type "::Encoding", "Kconv::JIS"
  end

  def test_NOCONV
    assert_const_type "nil", "Kconv::NOCONV"
  end

  def test_SJIS
    assert_const_type "::Encoding", "Kconv::SJIS"
  end

  def test_UNKNOWN
    assert_const_type "nil", "Kconv::UNKNOWN"
  end

  def test_UTF16
    assert_const_type "::Encoding", "Kconv::UTF16"
  end

  def test_UTF32
    assert_const_type "::Encoding", "Kconv::UTF32"
  end

  def test_UTF8
    assert_const_type "::Encoding", "Kconv::UTF8"
  end

  def test_guess
    assert_send_type "(::String str) -> ::Encoding?",
                     Kconv, :guess, ""
  end

  def test_iseuc
    assert_send_type "(::String str) -> bool",
                     Kconv, :iseuc, ""
  end

  def test_isjis
    assert_send_type "(::String str) -> bool",
                     Kconv, :isjis, ""
  end

  def test_issjis
    assert_send_type "(::String str) -> bool",
                     Kconv, :issjis, ""
  end

  def test_isutf8
    assert_send_type "(::String str) -> bool",
                     Kconv, :isutf8, ""
  end

  def test_kconv
    assert_send_type "(::String str, ::Encoding? out_code, ?::Encoding? in_code) -> ::String",
                     Kconv, :kconv, "", Kconv::UTF8
  end

  def test_toeuc
    assert_send_type "(::String str) -> ::String",
                     Kconv, :toeuc, ""
  end

  def test_tojis
    assert_send_type "(::String str) -> ::String",
                     Kconv, :tojis, ""
  end

  def test_tolocale
    assert_send_type "(::String str) -> ::String",
                     Kconv, :tolocale, ""
  end

  def test_tosjis
    assert_send_type "(::String str) -> ::String",
                     Kconv, :tosjis, ""
  end

  def test_toutf16
    assert_send_type "(::String str) -> ::String",
                     Kconv, :toutf16, ""
  end

  def test_toutf32
    assert_send_type "(::String str) -> ::String",
                     Kconv, :toutf32, ""
  end

  def test_toutf8
    assert_send_type "(::String str) -> ::String",
                     Kconv, :toutf8, ""
  end
end
