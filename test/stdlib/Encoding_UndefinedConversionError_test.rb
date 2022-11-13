require_relative "test_helper"

class Encoding::UndefinedConversionErrorTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::Encoding::UndefinedConversionError"

  def test_destination_encoding
    assert_send_type  "() -> ::Encoding",
                      error_object, :destination_encoding
  end

  def test_destination_encoding_name
    assert_send_type  "() -> ::String",
                      error_object, :destination_encoding_name
  end

  def test_error_char
    assert_send_type  "() -> ::String",
                      error_object, :error_char
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
    ec = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec.primitive_convert("\xa4\xa2", "")
    ec.last_error
  end
end
