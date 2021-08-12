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

class OpenSSLCipherSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::Cipher)"

  def test_ciphers
    assert_send_type "() -> Array[String]",
      OpenSSL::Cipher, :ciphers

  end
end


class OpenSSLCipherTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::Cipher"

  def encrypt_decrypt
    key = ["2b7e151628aed2a6abf7158809cf4f3c"].pack("H*")
    iv =  ["000102030405060708090a0b0c0d0e0f"].pack("H*")
    pt =  ["6bc1bee22e409f96e93d7e117393172a" \
           "ae2d8a571e03ac9c9eb76fac45af8e51"].pack("H*")
    ct =  ["7649abac8119b246cee98e9b12e9197d" \
           "5086cb9b507219ee95db113a917678b2"].pack("H*")
    cipher = new_encryptor("aes-128-cbc", key: key, iv: iv, padding: 0)
    assert_send_type "(String) -> String",
      cipher, :update, pt
    assert_send_type "() -> String",
      cipher, :final
    cipher = new_decryptor("aes-128-cbc", key: key, iv: iv, padding: 0)
    assert_equal pt, cipher.update(ct) << cipher.final
    assert_send_type "(String) -> String",
      cipher, :update, ct
    assert_send_type "() -> String",
      cipher, :final
  end

  def test_aes_gcm
    # RFC 3610 Section 8, Test Case 1
    key = ["feffe9928665731c6d6a8f9467308308"].pack("H*")
    iv =  ["cafebabefacedbaddecaf888"].pack("H*")
    aad = ["feedfacedeadbeeffeedfacedeadbeef" \
           "abaddad2"].pack("H*")
    pt =  ["d9313225f88406e5a55909c5aff5269a" \
           "86a7a9531534f7da2e4c303d8a318a72" \
           "1c3c0c95956809532fcf0e2449a6b525" \
           "b16aedf5aa0de657ba637b39"].pack("H*")
    ct =  ["42831ec2217774244b7221b784d0d49c" \
           "e3aa212f2c02a4e035c17e2329aca12e" \
           "21d514b25466931c7d8f6a5aac84aa05" \
           "1ba30b396a0aac973d58e091"].pack("H*")
    tag = ["5bc94fbc3221a5db94fae95ae7121a47"].pack("H*")


    cipher = new_encryptor("aes-128-gcm", key: key, iv: iv, auth_data: aad)
    assert_send_type "(String) -> String",
      cipher, :update, pt
    assert_send_type "() -> String",
      cipher, :final
    assert_send_type "() -> String",
      cipher, :auth_tag
    assert_send_type "(Integer) -> String",
      cipher, :auth_tag, 8
      cipher = new_decryptor("aes-128-gcm", key: key, iv: iv, auth_tag: tag, auth_data: aad)
    assert_send_type "(String) -> String",
      cipher, :update, ct
    assert_send_type "() -> String",
      cipher, :final
  end

  def test_funcs
    cipher = new_encryptor("aes-128-cbc")
    assert_send_type "() -> String",
      cipher, :name
    assert_send_type "() -> String",
      cipher, :random_key
    assert_send_type "() -> String",
      cipher, :random_iv
    assert_send_type "() -> OpenSSL::Cipher",
      cipher, :reset
  end

  private

  def new_encryptor(algo, **kwargs)
    OpenSSL::Cipher.new(algo).tap do |cipher|
      assert_send_type "() -> OpenSSL::Cipher",
        cipher, :encrypt
      kwargs.each do|k, v|
        assert_send_type "(#{v.class}) -> #{v.class}",
          cipher, :"#{k}=", v
      end
    end
  end

  def new_decryptor(algo, **kwargs)
    OpenSSL::Cipher.new(algo).tap do |cipher|
      assert_send_type "() -> OpenSSL::Cipher",
        cipher, :decrypt
      kwargs.each do |k, v|
        assert_send_type "(#{v.class}) -> #{v.class}",
          cipher, :"#{k}=", v
      end
    end
  end
end

class OpenSSLConfigSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::Config)"

  def test_load
    assert_send_type "() -> OpenSSL::Config",
      OpenSSL::Config, :load
    assert_send_type "(String) -> OpenSSL::Config",
      OpenSSL::Config, :load, OpenSSL::Config::DEFAULT_CONFIG_FILE
  end

  def test_parse
    assert_send_type "(String) -> OpenSSL::Config",
      OpenSSL::Config, :parse, File.read(OpenSSL::Config::DEFAULT_CONFIG_FILE)

  end

  def test_parse_config
    assert_send_type "(File) -> Hash[String, Hash[String, String]]",
      OpenSSL::Config, :parse_config, File.open(OpenSSL::Config::DEFAULT_CONFIG_FILE)

  end
end

class OpenSSLConfigTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::Config"

  def test_sections
    assert_send_type "() -> Array[String]",
      config, :sections
  end

  def test_lookup_and_set
    assert_send_type "(String) -> untyped",
      config, :[], "default"
    assert_send_type "(String, String) -> String",
      config, :get_value, "default", "oid_section"
  end

  def test_each
    assert_send_type "() { (String, String, String) -> void } -> OpenSSL::Config",
      config, :each do |*k| return k; end
  end

  private

  def config
    OpenSSL::Config.load(OpenSSL::Config::DEFAULT_CONFIG_FILE)
  end
end

class OpenSSLDigestSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::Digest)"

  def test_digest
    assert_send_type "(String, String) -> String",
      OpenSSL::Digest, :digest, "SHA256", "abc"
  end
end

class OpenSSLDigestTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::Digest"

  def test_block_length
    assert_send_type "() -> Integer",
      digest, :block_length
  end

  def test_digest_length
    assert_send_type "() -> Integer",
      digest, :digest_length
  end

  def test_name
    assert_send_type "() -> String",
      digest, :name
  end

  def test_reset
    assert_send_type "() -> OpenSSL::Digest",
      digest, :reset
  end

  def test_update
    assert_send_type "(String) -> OpenSSL::Digest",
      digest, :update, "cde"
  end

  private

  def digest
    OpenSSL::Digest.new("sha256")
  end
end

class OpenSSLEngineSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::Engine)"

  def test_by_id
    assert_send_type "(String) -> OpenSSL::Engine",
      OpenSSL::Engine, :by_id, "openssl"
  end

  def test_engines
    assert_send_type "() -> Array[OpenSSL::Engine]",
      OpenSSL::Engine, :engines
  end
end

class OpenSSLEngineTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::Engine"

  def test_cipher
    assert_send_type "(String) -> OpenSSL::Cipher",
      engine, :cipher, "RC4"
  end

  def test_digest
    assert_send_type "(String) -> OpenSSL::Digest",
      engine, :digest, "SHA1"
  end

  private

  def engine
    OpenSSL::Engine.by_id("openssl")
  end
end

class OpenSSLHMACSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::HMAC)"

  def test_digest
    assert_send_type "(String, String, String) -> String",
      OpenSSL::HMAC, :digest, "SHA256", "key", "data"
  end

  def test_hexdigest
    assert_send_type "(String, String, String) -> String",
      OpenSSL::HMAC, :hexdigest, "SHA256", "key", "data"
  end
end

class OpenSSLHMACTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "::OpenSSL::HMAC"

  def test_digest
    assert_send_type "() -> String",
      hmac, :digest
  end

  def test_hexdigest
    assert_send_type "() -> String",
      hmac, :hexdigest
  end

  def test_reset
    assert_send_type "() -> OpenSSL::HMAC",
      hmac, :reset
  end

  def test_update
    assert_send_type "(String) -> OpenSSL::HMAC",
      hmac, :update, "cde"
  end

  private

  def hmac
    digest = OpenSSL::Digest.new('SHA256')
    OpenSSL::HMAC.new("key", digest)
  end
end

class OpenSSLKDFSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL::KDF)"

  def test_hkdf
    hash = "sha256"
    ikm = "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"
    salt = "000102030405060708090a0b0c"
    info = "f0f1f2f3f4f5f6f7f8f9"
    l = 42
    assert_send_type "(String, salt: String, info: String, length: Integer, hash: String) -> String",
      OpenSSL::KDF, :hkdf, ikm, salt: salt, info: info, length: l, hash: hash
  end

  def test_pbkdf2_hmac
    p ="password"
    s = "salt"
    c = 1
    dk_len = 20

    assert_send_type "(String, salt: String, iterations: Integer, length: Integer, hash: String) -> String",
      OpenSSL::KDF, :pbkdf2_hmac, p, salt: s, iterations: c, length: dk_len, hash: "sha1"
    assert_send_type "(String, salt: String, iterations: Integer, length: Integer, hash: OpenSSL::Digest) -> String",
      OpenSSL::KDF, :pbkdf2_hmac, p, salt: s, iterations: c, length: dk_len, hash: OpenSSL::Digest::SHA1.new
  end

  def test_scrypt
    pass = ""
    salt = ""
    n = 16
    r = 1
    p = 1
    dklen = 64

    assert_send_type "(String, salt: String, N: Integer, r: Integer, p: Integer, length: Integer) -> String",
      OpenSSL::KDF, :scrypt, pass, salt: salt, N: n, r: r, p: p, length: dklen
  end
end