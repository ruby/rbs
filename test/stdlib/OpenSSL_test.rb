require_relative "test_helper"
require "openssl"

class OpenSSLSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL)"

  def test_Digest
    assert_send_type "(String) -> singleton(::OpenSSL::Digest)",
                     OpenSSL, :Digest, "MD5"
  end

  def test_debug
    assert_send_type "() -> bool",
                     OpenSSL, :debug
  end

  def test_errors
    assert_send_type "() -> Array[String]",
                     OpenSSL, :errors
  end

  def test_fips_mode
    assert_send_type "() -> bool",
                     OpenSSL, :fips_mode
  end

  def test_fixed_length_secure_compare
    assert_send_type "(String, String) -> bool",
                     OpenSSL, :fixed_length_secure_compare, "a", "a"
  end

  def test_secure_compare
    assert_send_type "(String, String) -> bool",
                     OpenSSL, :secure_compare, "a", "a"
  end
end


class OpenSSLASN1SingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::ASN1)"

  %i[
    BMPString
    BitString
    GeneralString
    GraphicString
    IA5String
    ISO64String
    OctetString
    PrintableString
    T61String
    UTF8String
    UniversalString
    VideotexString
  ].each do |type|
    define_method :"test_#{type}" do
      assert_send_type "(String) -> OpenSSL::ASN1::#{type}",
      OpenSSL::ASN1, type, "bang"
      assert_send_type "(String, ::Integer) -> OpenSSL::ASN1::#{type}",
      OpenSSL::ASN1, type, "bang", 2
      assert_send_type "(String, ::Integer, Symbol) -> OpenSSL::ASN1::#{type}",
      OpenSSL::ASN1, type, "bang", 2, :IMPLICIT
    end
  end

  def test_ObjectId
    assert_send_type "(::String) -> OpenSSL::ASN1::ObjectId",
    OpenSSL::ASN1, :ObjectId, "1.2"
    assert_send_type "(::String, ::Integer) -> OpenSSL::ASN1::ObjectId",
    OpenSSL::ASN1, :ObjectId, "1.2", 2
    assert_send_type "(::String, ::Integer, Symbol) -> OpenSSL::ASN1::ObjectId",
    OpenSSL::ASN1, :ObjectId, "1.2", 2, :IMPLICIT
  end

  def test_Boolean
    assert_send_type "(bool) -> OpenSSL::ASN1::Boolean",
    OpenSSL::ASN1, :Boolean, true
    assert_send_type "(bool, ::Integer) -> OpenSSL::ASN1::Boolean",
    OpenSSL::ASN1, :Boolean, true, 2
    assert_send_type "(bool, ::Integer, Symbol) -> OpenSSL::ASN1::Boolean",
    OpenSSL::ASN1, :Boolean, true, 2, :IMPLICIT
  end

  def test_EndOfContent
    assert_send_type "() -> OpenSSL::ASN1::EndOfContent",
    OpenSSL::ASN1, :EndOfContent
  end


  def test_Integer
    assert_send_type "(::Integer) -> OpenSSL::ASN1::Integer",
    OpenSSL::ASN1, :Integer, 2
    assert_send_type "(::Integer, ::Integer) -> OpenSSL::ASN1::Integer",
    OpenSSL::ASN1, :Integer, 2, 2
    assert_send_type "(::Integer, ::Integer, Symbol) -> OpenSSL::ASN1::Integer",
    OpenSSL::ASN1, :Integer, 2, 2, :IMPLICIT
  end

  def test_Enumerated
    assert_send_type "(::Integer) -> OpenSSL::ASN1::Enumerated",
    OpenSSL::ASN1, :Enumerated, 2
    assert_send_type "(::Integer, ::Integer) -> OpenSSL::ASN1::Enumerated",
    OpenSSL::ASN1, :Enumerated, 2, 2
    assert_send_type "(::Integer, ::Integer, Symbol) -> OpenSSL::ASN1::Enumerated",
    OpenSSL::ASN1, :Enumerated, 2, 2, :IMPLICIT
  end

  def test_GeneralizedTime
    assert_send_type "(::Time) -> OpenSSL::ASN1::GeneralizedTime",
    OpenSSL::ASN1, :GeneralizedTime, Time.now
    assert_send_type "(::Time, ::Integer) -> OpenSSL::ASN1::GeneralizedTime",
    OpenSSL::ASN1, :GeneralizedTime, Time.now, 2
    assert_send_type "(::Time, ::Integer, Symbol) -> OpenSSL::ASN1::GeneralizedTime",
    OpenSSL::ASN1, :GeneralizedTime, Time.now, 2, :IMPLICIT
  end

  def test_UTCTime
    assert_send_type "(::Time) -> OpenSSL::ASN1::UTCTime",
    OpenSSL::ASN1, :UTCTime, Time.now
    assert_send_type "(::Time, ::Integer) -> OpenSSL::ASN1::UTCTime",
    OpenSSL::ASN1, :UTCTime, Time.now, 2
    assert_send_type "(::Time, ::Integer, Symbol) -> OpenSSL::ASN1::UTCTime",
    OpenSSL::ASN1, :UTCTime, Time.now, 2, :IMPLICIT
  end

  def test_Null
    assert_send_type "(nil) -> OpenSSL::ASN1::Null",
    OpenSSL::ASN1, :Null, nil
  end

  def test_Sequence
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data]) -> OpenSSL::ASN1::Sequence",
    OpenSSL::ASN1, :Sequence, [OpenSSL::ASN1::Null(nil)]
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data], ::Integer) -> OpenSSL::ASN1::Sequence",
    OpenSSL::ASN1, :Sequence, [OpenSSL::ASN1::Null(nil)], 2
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data], ::Integer, Symbol) -> OpenSSL::ASN1::Sequence",
    OpenSSL::ASN1, :Sequence, [OpenSSL::ASN1::Null(nil)], 2, :IMPLICIT
  end

  def test_Set
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data]) -> OpenSSL::ASN1::Set",
    OpenSSL::ASN1, :Set, [OpenSSL::ASN1::Null(nil)]
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data], ::Integer) -> OpenSSL::ASN1::Set",
    OpenSSL::ASN1, :Set, [OpenSSL::ASN1::Null(nil)], 2
    assert_send_type "(Array[OpenSSL::ASN1::ASN1Data], ::Integer, Symbol) -> OpenSSL::ASN1::Set",
    OpenSSL::ASN1, :Set, [OpenSSL::ASN1::Null(nil)], 2, :IMPLICIT
  end

  def test_decode
    der = "\x05\x00".b
    assert_send_type "(String) -> OpenSSL::ASN1::ASN1Data",
    OpenSSL::ASN1, :decode, der
    # assert_send_type "(_ToDer) -> OpenSSL::ASN1::ASN1Data",
    # OpenSSL::ASN1, :decode, Class.new { def to_der; der; end }
  end

  def test_decode_all
    der = "\x05\x00\x05\x00".b
    assert_send_type "(String) -> Array[OpenSSL::ASN1::ASN1Data]",
    OpenSSL::ASN1, :decode_all, der
    # assert_send_type "(_ToDer) -> Array[OpenSSL::ASN1::ASN1Data]",
    # OpenSSL::ASN1, :decode, Class.new { def to_der; der; end }
  end

  def test_traverse
    der = "\x05\x00\x05\x00".b
    assert_send_type "(String) { (::Integer, ::Integer, ::Integer, ::Integer, bool, Symbol, ::Integer) -> void } -> void",
    OpenSSL::ASN1, :traverse, der  do |a, b, c, d, e, f, g| return a, b, c, d, e, f, g end
  end
end

class OpenSSLASN1ASN1DataTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::ASN1::ASN1Data"

  def test_indefinite_length
    assert_send_type "() -> bool",
    OpenSSL::ASN1::ASN1Data.new(2, 2, :UNIVERSAL), :indefinite_length
    assert_send_type "(bool) -> bool",
    OpenSSL::ASN1::ASN1Data.new(2, 2, :UNIVERSAL), :indefinite_length=, true
  end

  def test_tag
    assert_send_type "() -> ::Integer",
    OpenSSL::ASN1::ASN1Data.new(2, 2, :UNIVERSAL), :tag
    assert_send_type "() -> OpenSSL::BN",
    OpenSSL::ASN1::ASN1Data.new(2, OpenSSL::BN.new(2), :UNIVERSAL), :tag
    assert_send_type "(::Integer) -> ::Integer",
    OpenSSL::ASN1::ASN1Data.new(2, 2, :UNIVERSAL), :tag=, 3
    assert_send_type "(OpenSSL::BN) -> OpenSSL::BN",
    OpenSSL::ASN1::ASN1Data.new(2, OpenSSL::BN.new(2), :UNIVERSAL), :tag=, OpenSSL::BN.new(3)
  end

  def test_tag_class
    assert_send_type "() -> Symbol",
    OpenSSL::ASN1::ASN1Data.new(2, 2, :UNIVERSAL), :tag_class
    assert_send_type "(Symbol) -> Symbol",
    OpenSSL::ASN1::ASN1Data.new(2, OpenSSL::BN.new(2), :UNIVERSAL), :tag_class=, :CONTEXT_SPECIFIC
  end

  def test_to_der
    assert_send_type "() -> String",
    OpenSSL::ASN1::ASN1Data.new("2", 2, :UNIVERSAL), :to_der
  end
end

class OpenSSLBNSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::BN)"

  def test_generate_prime
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN, :generate_prime, 3
  end


end

class OpenSSLBNTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::BN"

  def test_operations
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :%, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :*, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :**, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :+, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :-, 2
    assert_send_type "(::Integer) -> [OpenSSL::BN, OpenSSL::BN]",
      OpenSSL::BN.new(2), :/, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :<<, 2
    assert_send_type "(::Integer) -> OpenSSL::BN",
      OpenSSL::BN.new(2), :>>, 2
  end
end