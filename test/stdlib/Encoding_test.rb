require_relative 'test_helper'

class EncodingSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Encoding)'

  def test__load
    [1, :a, 'hello', Object.new, Encoding::UTF_8].each do |enc|
      assert_send_type  '[T] (T) -> T',
                        Encoding, :_load, enc
    end
  end

  def test_locale_charmap
    assert_send_type  '() -> String',
                      Encoding, :locale_charmap
  end

  def test_aliases
    assert_send_type  '() -> Hash[String, String]',
                      Encoding, :aliases
  end

  def test_compatible?
    assert_send_type  '(untyped, untyped) -> Encoding?',
                      Encoding, :compatible?, /a/, 'a'
    assert_send_type  '(untyped, untyped) -> Encoding?',
                      Encoding, :compatible?, 1r, Object.new
    assert_send_type  '(untyped, untyped) -> Encoding?',
                      Encoding, :compatible?, $stdout, $stdin
  end

  def test_default_external_and_default_external=
    old_enc = Encoding.default_external

    assert_send_type  '() -> Encoding',
                      Encoding, :default_external

    assert_send_type  '(Encoding) -> Encoding',
                      Encoding, :default_external=, Encoding::UTF_8

    with_string 'UTF-8' do |enc|
      assert_send_type  '[T < _ToStr] (T) -> T',
                        Encoding, :default_external=, enc
      assert_send_type  '() -> Encoding',
                        Encoding, :default_external
    end
  ensure
    Encoding.default_external = old_enc
  end

  def test_default_internal_and_default_internal=
    old_enc = Encoding.default_internal

    assert_send_type  '(nil) -> nil',
                      Encoding, :default_internal=, nil
    assert_send_type  '() -> Encoding?',
                      Encoding, :default_internal

    assert_send_type  '(Encoding) -> Encoding',
                      Encoding, :default_internal=, Encoding::UTF_8

    with_string 'UTF-8' do |enc|
      assert_send_type  '[T < _ToStr] (T) -> T',
                        Encoding, :default_internal=, enc
      assert_send_type  '() -> Encoding?',
                        Encoding, :default_internal
    end
  ensure
    Encoding.default_internal = old_enc
  end

  def test_find
    with_encoding 'UTF-8' do |enc|
      assert_send_type  '(encoding enc) -> Encoding',
                        Encoding, :find, enc
    end

    begin
      old_enc = Encoding.default_internal

      Encoding.default_internal = nil
      with_encoding 'internal' do |enc|
        assert_send_type  '(encoding enc) -> nil',
                          Encoding, :find, enc
      end
    ensure
      Encoding.default_internal = old_enc
    end
  end

  def test_list
    assert_send_type  '() -> Array[Encoding]',
                      Encoding, :list
  end

  def test_name_list
    assert_send_type  '() -> Array[String]',
                      Encoding, :name_list
  end
end

class EncodingInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Encoding'

  def test_ascii_compatible?
    assert_send_type  '() -> bool',
                      Encoding::UTF_8, :ascii_compatible?

    assert_send_type  '() -> bool',
                      Encoding::UTF_16, :ascii_compatible?
  end


  def test_dummy?
    assert_send_type  '() -> bool',
                      Encoding::ISO_2022_JP, :dummy?

    assert_send_type  '() -> bool',
                      Encoding::UTF_8, :dummy?
  end

  def test_inspect
    assert_send_type  '() -> String',
                      Encoding::UTF_8, :inspect
  end

  def test_name
    assert_send_type  '() -> String',
                      Encoding::UTF_8, :name
  end

  def test_names
    assert_send_type  '() -> Array[String]',
                      Encoding::WINDOWS_31J, :names
  end

  def test_to_s
    assert_send_type  '() -> String',
                      Encoding::UTF_8, :to_s
  end

  KNOWN_ENCODINGS = %i[
    ANSI_X3_4_1968 ASCII ASCII_8BIT BIG5 BIG5_HKSCS BIG5_HKSCS_2008 BIG5_UAO BINARY Big5 Big5_HKSCS
    Big5_HKSCS_2008 Big5_UAO CESU_8 CP1250 CP1251 CP1252 CP1253 CP1254 CP1255 CP1256 CP1257 CP1258
    CP437 CP50220 CP50221 CP51932 CP65000 CP65001 CP737 CP775 CP850 CP852 CP855 CP857 CP860 CP861
    CP862 CP863 CP864 CP865 CP866 CP869 CP874 CP878 CP932 CP936 CP949 CP950 CP951 CSWINDOWS31J
    CsWindows31J EBCDIC_CP_US EMACS_MULE EUCCN EUCJP EUCJP_MS EUCKR EUCTW EUC_CN EUC_JISX0213
    EUC_JIS_2004 EUC_JP EUC_JP_MS EUC_KR EUC_TW Emacs_Mule EucCN EucJP EucJP_ms EucKR EucTW GB12345
    GB18030 GB1988 GB2312 GBK IBM037 IBM437 IBM737 IBM720 CP720 IBM775 IBM850 IBM852 IBM855 IBM857
    IBM860 IBM861 IBM862 IBM863 IBM864 IBM865 IBM866 IBM869 ISO2022_JP ISO2022_JP2 ISO8859_1
    ISO8859_10 ISO8859_11 ISO8859_13 ISO8859_14 ISO8859_15 ISO8859_16 ISO8859_2 ISO8859_3 ISO8859_4
    ISO8859_5 ISO8859_6 ISO8859_7 ISO8859_8 ISO8859_9 ISO_2022_JP ISO_2022_JP_2 ISO_2022_JP_KDDI
    ISO_8859_1 ISO_8859_10 ISO_8859_11 ISO_8859_13 ISO_8859_14 ISO_8859_15 ISO_8859_16 ISO_8859_2
    ISO_8859_3 ISO_8859_4 ISO_8859_5 ISO_8859_6 ISO_8859_7 ISO_8859_8 ISO_8859_9 KOI8_R KOI8_U
    MACCENTEURO MACCROATIAN MACCYRILLIC MACGREEK MACICELAND MACJAPAN MACJAPANESE MACROMAN MACROMANIA
    MACTHAI MACTURKISH MACUKRAINE MacCentEuro MacCroatian MacCyrillic MacGreek MacIceland MacJapan
    MacJapanese MacRoman MacRomania MacThai MacTurkish MacUkraine PCK SHIFT_JIS SJIS SJIS_DOCOMO
    SJIS_DoCoMo SJIS_KDDI SJIS_SOFTBANK SJIS_SoftBank STATELESS_ISO_2022_JP
    STATELESS_ISO_2022_JP_KDDI Shift_JIS Stateless_ISO_2022_JP Stateless_ISO_2022_JP_KDDI TIS_620
    UCS_2BE UCS_4BE UCS_4LE US_ASCII UTF8_DOCOMO UTF8_DoCoMo UTF8_KDDI UTF8_MAC UTF8_SOFTBANK
    UTF8_SoftBank UTF_16 UTF_16BE UTF_16LE UTF_32 UTF_32BE UTF_32LE UTF_7 UTF_8 UTF_8_HFS UTF_8_MAC
    WINDOWS_1250 WINDOWS_1251 WINDOWS_1252 WINDOWS_1253 WINDOWS_1254 WINDOWS_1255 WINDOWS_1256
    WINDOWS_1257 WINDOWS_1258 WINDOWS_31J WINDOWS_874 Windows_1250 Windows_1251 Windows_1252
    Windows_1253 Windows_1254 Windows_1255 Windows_1256 Windows_1257 Windows_1258 Windows_31J
    Windows_874
  ]

  def test_encoding_constants
    KNOWN_ENCODINGS.each do |encoding|
      assert_const_type 'Encoding', "Encoding::#{encoding}"
    end
  end
end

class Encoding::ConverterSingletonTest < Test::Unit::TestCase
  include TestHelper

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
  include TestHelper

  testing "::Encoding::Converter"

  def test_double_equal
    assert_send_type(
      "(Encoding::Converter) -> bool",
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
    invalid_ec.primitive_convert(+"\xf1abcd", +"")
    assert_send_type(
      "() -> Encoding::InvalidByteSequenceError",
      invalid_ec, :last_error
    )

    undefined_ec = Encoding::Converter.new("ISO-8859-1", "EUC-JP")
    undefined_ec.primitive_convert(+"\xa0", +"")
    assert_send_type(
      "() -> Encoding::UndefinedConversionError",
      undefined_ec, :last_error
    )
  end

  def test_primitive_convert
    assert_send_type(
      "(String, String) -> :finished",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      +"Foo", +""
    )
    assert_send_type(
      "(String, String, nil, nil) -> :finished",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      +"Foo", +"", nil, nil
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :destination_buffer_full",
      Encoding::Converter.new("UTF-8", "UTF-16BE"), :primitive_convert,
      +"Foo", +"", nil, 1
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :invalid_byte_sequence",
      Encoding::Converter.new("EUC-JP", "Shift_JIS"), :primitive_convert,
      +"\xff", +"", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :undefined_conversion",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      +"\xa4\xa2", +"", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer) -> :incomplete_input",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      +"\xa4", +"", nil, 10
    )
    assert_send_type(
      "(String, String, nil, Integer, Integer) -> :source_buffer_empty",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      +"\xa4", +"", nil, 10, Encoding::Converter::PARTIAL_INPUT
    )
    assert_send_type(
      "(String, String, nil, Integer, partial_input: true) -> :source_buffer_empty",
      Encoding::Converter.new("EUC-JP", "ISO-8859-1"), :primitive_convert,
      +"\xa4", +"", nil, 10, partial_input: true
    )

    # TODO: Add after_output test case
  end

  def test_primitive_errinfo
    ec1 = Encoding::Converter.new("EUC-JP", "Shift_JIS")
    ec1.primitive_convert(+"\xff", +"", nil, 10)
    assert_send_type(
      "() -> [:invalid_byte_sequence, String, String, String, String]",
      ec1, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert(+"\xa4\xa2", +"", nil, 10)
    assert_send_type(
      "() -> [:undefined_conversion, String, String, String, String]",
      ec2, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert(+"\xa4", +"", nil, 10)
    assert_send_type(
      "() -> [:incomplete_input, String, String, String, String]",
      ec2, :primitive_errinfo
    )

    ec2 = Encoding::Converter.new("EUC-JP", "ISO-8859-1")
    ec2.primitive_convert(+"\xa4", +"", nil, 10, Encoding::Converter::PARTIAL_INPUT)
    assert_send_type(
      "() -> [:source_buffer_empty, nil, nil, nil, nil]",
      ec2, :primitive_errinfo
    )

    # TODO: Add after_output test case
  end

  def test_putback
    ec = Encoding::Converter.new("UTF-16LE", "ISO-8859-1")
    ec.primitive_convert(+"\x00\xd8\x61\x00", +"") # => :invalid_byte_sequence
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

class Encoding_CompatibilityErrorInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Encoding::CompatibilityError'
end

class Encoding_ConverterNotFoundErrorInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Encoding::ConverterNotFoundError'
end

class Encoding_InvalidByteSequenceErrorInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Encoding::InvalidByteSequenceError'

  def test_destination_encoding
    assert_send_type  '() -> ::Encoding',
                      error_object, :destination_encoding
  end

  def test_destination_encoding_name
    assert_send_type  '() -> ::String',
                      error_object, :destination_encoding_name
  end

  def test_error_bytes
    assert_send_type  '() -> ::String',
                      error_object, :error_bytes
  end

  def test_incomplete_input?
    assert_send_type  '() -> bool',
                      error_object, :incomplete_input?
  end

  def test_readagain_bytes
    assert_send_type  '() -> ::String',
                      error_object, :readagain_bytes
  end

  def test_source_encoding
    assert_send_type  '() -> ::Encoding',
                      error_object, :source_encoding
  end

  def test_source_encoding_name
    assert_send_type  '() -> ::String',
                      error_object, :source_encoding_name
  end

  private

  def error_object
    ec = Encoding::Converter.new('UTF-8', 'ISO-8859-1')
    ec.primitive_convert(+"\xf1abcd", +'')
    ec.last_error
  end
end

class Encoding_UndefinedConversionErrorTest < Test::Unit::TestCase
  include TestHelper

  testing '::Encoding::UndefinedConversionError'

  def test_destination_encoding
    assert_send_type  '() -> ::Encoding',
                      error_object, :destination_encoding
  end

  def test_destination_encoding_name
    assert_send_type  '() -> ::String',
                      error_object, :destination_encoding_name
  end

  def test_error_char
    assert_send_type  '() -> ::String',
                      error_object, :error_char
  end

  def test_source_encoding
    assert_send_type  '() -> ::Encoding',
                      error_object, :source_encoding
  end

  def test_source_encoding_name
    assert_send_type  '() -> ::String',
                      error_object, :source_encoding_name
  end

  private

  def error_object
    ec = Encoding::Converter.new('EUC-JP', 'ISO-8859-1')
    ec.primitive_convert(+"\xa4\xa2", +'')
    ec.last_error
  end
end
