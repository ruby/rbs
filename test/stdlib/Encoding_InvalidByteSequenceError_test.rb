require_relative "test_helper"


class Encoding::InvalidByteSequenceErrorTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::Encoding::InvalidByteSequenceError"

  def test_destination_encoding
    assert_send_type  "() -> ::Encoding",
                      error_object, :destination_encoding
  end

  def test_destination_encoding_name
    assert_send_type  "() -> ::String",
                      error_object, :destination_encoding_name
  end

  def test_error_bytes
    assert_send_type  "() -> ::String",
                      error_object, :error_bytes
  end

  def test_incomplete_input?
    assert_send_type  "() -> bool",
                      error_object, :incomplete_input?
  end

  def test_readagain_bytes
    assert_send_type  "() -> ::String",
                      error_object, :readagain_bytes
  end

  def test_source_encoding
    assert_send_type  "() -> ::Encoding",
                      error_object, :source_encoding
  end

  def test_source_encoding_name
    assert_send_type  "() -> ::String",
                      error_object, :source_encoding_name
  end

  private

  def error_object
    ec = Encoding::Converter.new("UTF-8", "ISO-8859-1")
    ec.primitive_convert("\xf1abcd", "")
    ec.last_error
  end
end
