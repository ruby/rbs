require_relative "test_helper"

class Encoding::ConverterSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Encoding::Converter)"

  def test_new
    assert_send_type(
      "(String, String) -> void",
      Encoding::Converter, :new, "UTF-8", "EUC-JP"
    )
    assert_send_type(
      "(Encoding, Encoding) -> void",
      Encoding::Converter, :new, Encoding::UTF_8, Encoding::EUC_JP
    )
    assert_send_type(
      "(Encoding, Encoding, invalid: :replace, undef: :replace, replace: String) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, invalid: :replace, undef: :replace, replace: "?"
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :universal) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :universal
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :crlf) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :crlf
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :cr) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :cr
    )
    assert_send_type(
      "(Encoding, Encoding, universal_newline: bool) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, universal_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, crlf_newline: bool) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, crlf_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, cr_newline: bool) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, cr_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, xml: :text) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, xml: :text
    )
    assert_send_type(
      "(Encoding, Encoding, xml: :attr) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, xml: :attr
    )
    assert_send_type(
      "(Encoding, Encoding, Integer) -> void",
      Encoding::Converter, :new,
      Encoding::UTF_8, Encoding::EUC_JP, Encoding::Converter::INVALID_REPLACE
    )
    assert_send_type(
      "([[String, String], 'universal_newline']) -> void",
      Encoding::Converter, :new,
      [['UTF-8', 'EUC-JP'], 'universal_newline']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'universal_newline']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'universal_newline']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'crlf_newline']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'crlf_newline']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'cr_newline']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'cr_newline']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'xml_text_escape']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'xml_text_escape']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'xml_attr_content_escape']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'xml_attr_content_escape']
    )
    assert_send_type(
      "([[Encoding, Encoding], 'xml_attr_quote']) -> void",
      Encoding::Converter, :new,
      [[Encoding::UTF_8, Encoding::EUC_JP], 'xml_attr_quote']
    )
  end

  def test_asciicompat_encoding
    assert_send_type(
      "(String) -> Encoding",
      Encoding::Converter, :asciicompat_encoding, "ISO-2022-JP"
    )
    assert_send_type(
      "(Encoding) -> Encoding",
      Encoding::Converter, :asciicompat_encoding, Encoding::ISO_2022_JP
    )
    assert_send_type(
      "(String) -> nil",
      Encoding::Converter, :asciicompat_encoding, "UTF-8"
    )
    assert_send_type(
      "(Encoding) -> nil",
      Encoding::Converter, :asciicompat_encoding, Encoding::UTF_8
    )
  end

  def test_search_convpath
    assert_send_type(
      "(String, String) -> Array[[Encoding, Encoding]]",
      Encoding::Converter, :search_convpath,
      "UTF-8", "EUC-JP"
    )
    assert_send_type(
      "(Encoding, Encoding) -> Array[[Encoding, Encoding]]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :universal) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :universal
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :crlf) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :crlf
    )
    assert_send_type(
      "(Encoding, Encoding, newline: :cr) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, newline: :cr
    )
    assert_send_type(
      "(Encoding, Encoding, universal_newline: true) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, universal_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, crlf_newline: true) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, crlf_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, cr_newline: true) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, cr_newline: true
    )
    assert_send_type(
      "(Encoding, Encoding, xml: :text) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, xml: :text
    )
    assert_send_type(
      "(Encoding, Encoding, xml: :attr) -> Array[[Encoding, Encoding] | String]",
      Encoding::Converter, :search_convpath,
      Encoding::UTF_8, Encoding::EUC_JP, xml: :attr
    )
  end
end

class Encoding::ConverterTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Encoding::Converter"

  def test_double_equal
    assert_send_type(
      "(self) -> bool",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :==, Encoding::Converter.new("UTF-8", "EUC-JP")
    )
  end

  # def test_initialize
  #   assert_send_type  "(*untyped) -> void",
  #                     Encoding::Converter.new, :initialize
  # end

  def test_inspect
    assert_send_type(
      "() -> String",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :inspect
    )
  end

  def test_convert
    assert_send_type(
      "(String) -> String",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :convert, "\u{3042}",
    )
  end

  def test_convpath
    assert_send_type(
      "() -> [[Encoding, Encoding]]",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :convpath
    )
  end

  def test_destination_encoding
    assert_send_type(
      "() -> Encoding",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :destination_encoding
    )
  end

  def test_finish
    assert_send_type(
      "() -> String",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :finish
    )
  end

  def test_insert_output
    assert_send_type(
      "(String) -> nil",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :insert_output, "Foo"
    )
  end

  def test_last_error
    invalid_ec = Encoding::Converter.new("UTF-8", "ISO-8859-1")
    invalid_ec.primitive_convert("\xf1abcd", "")
    assert_send_type(
      "() -> Encoding::InvalidByteSequenceError",
      invalid_ec, :last_error
    )

    undefined_ec = Encoding::Converter.new("ISO-8859-1", "EUC-JP")
    undefined_ec.primitive_convert("\xa0", "")
    assert_send_type(
      "() -> Encoding::UndefinedConversionError",
      undefined_ec, :last_error
    )
  end

  def test_primitive_convert
    assert_send_type(
      "(String, String) -> :finished",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      "Foo", ""
    )
    assert_send_type(
      "(String, String, nil, nil) -> :finished",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      "Foo", "", nil, nil
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :destination_buffer_full",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      "Foo", "", nil, 1
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :invalid_byte_sequence",
      Encoding::Converter.new("EUC-JP", "Shift_JIS"), :primitive_convert,
      "\xff", "", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :undefined_conversion",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      "\xa4\xa2", "", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :incomplete_input",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      "\xa4", "", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer, Integer) -> :source_buffer_empty",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      "\xa4", "", nil, 10, Encoding::Converter::PARTIAL_INPUT
    )
    assert_send_type(
      "(String, String, nil, Integer, partial_input: true) -> :source_buffer_empty",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      "\xa4", "", nil, 10, partial_input: true
    )

    # TODO: Add after_output test case
  end

  def test_primitive_errinfo
    ec1 = Encoding::Converter.new("EUC-JP", "Shift_JIS")
    ec1.primitive_convert("\xff", "", nil, 10)
    assert_send_type(
      "() -> [:invalid_byte_sequence, String, String, String, String]",
      ec1, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert("\xa4\xa2", "", nil, 10)
    assert_send_type(
      "() -> [:undefined_conversion, String, String, String, String]",
      ec2, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert("\xa4", "", nil, 10)
    assert_send_type(
      "() -> [:incomplete_input, String, String, String, String]",
      ec2, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert("\xa4", "", nil, 10, Encoding::Converter::PARTIAL_INPUT)
    assert_send_type(
      "() -> [:source_buffer_empty, nil, nil, nil, nil]",
      ec2, :primitive_errinfo
    )

    # TODO: Add after_output test case
  end

  def test_putback
    ec = Encoding::Converter.new("UTF-16LE", "ISO-8859-1")
    ec.primitive_convert("\x00\xd8\x61\x00", "") # => :invalid_byte_sequence
    assert_send_type(
      "() -> String",
      ec, :putback
    )
    assert_send_type(
      "(Integer) -> String",
      ec, :putback, 1
    )
  end

  def test_replacement
    assert_send_type(
      "() -> String",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :replacement
    )
  end

  def test_replacement=
    assert_send_type(
      "(String) -> String",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :replacement=, "Foo"
    )
  end

  def test_source_encoding
    assert_send_type(
      "() -> Encoding",
      Encoding::Converter.new("UTF-8", "EUC-JP"), :source_encoding
    )
  end
end
