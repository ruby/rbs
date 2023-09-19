require_relative 'test_helper'

class EncodingSingletonTest < Test::Unit::TestCase
  include TypeAssertions

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
  include TypeAssertions

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

class Encoding_CompatibilityErrorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::Encoding::CompatibilityError'
end

class Encoding_ConverterNotFoundErrorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::Encoding::ConverterNotFoundError'
end

class Encoding_InvalidByteSequenceErrorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

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
    ec.primitive_convert("\xf1abcd", '')
    ec.last_error
  end
end

class Encoding_UndefinedConversionErrorTest < Test::Unit::TestCase
  include TypeAssertions

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
    ec.primitive_convert("\xa4\xa2", '')
    ec.last_error
  end
end
