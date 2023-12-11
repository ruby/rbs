require_relative 'test_helper'

# TODO: encode, encode!, byteslice
class StringSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::String)'

  def test_try_convert
    assert_send_type  '(String) -> String',
                      String, :try_convert, 'foo'

    assert_send_type  '(_ToStr) -> String',
                      String, :try_convert, ToStr.new

    with_untyped do |object|
      # These are covered by the previous cases.
      next if ::Kernel.instance_method(:respond_to?).bind_call(object, :to_str)

      assert_send_type  '(untyped) -> nil',
                        String, :try_convert, object
    end
  end
end

# Note, all methods which modify string literals have `+'string'` in case we later add
# `frozen_string_literal: true` to the top (or ruby makes frozen strings default).
class StringInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::String'

  def assert_case_method(method, include_fold: false)
    assert_send_type  '() -> String',
                      'hello', method
    options = %i[ascii lithuanian turkic] + (include_fold ? [:fold] : [])

    options.each do |option|
      assert_send_type  "(#{options.map(&:inspect).join('|')}) -> String",
                        'hello', method, option
    end

    assert_send_type  '(:lithuanian, :turkic) -> String',
                      'hello', method, :lithuanian, :turkic
    assert_send_type  '(:turkic, :lithuanian) -> String',
                      'hello', method, :turkic, :lithuanian
  end

  def assert_case_method!(method, normal:, nochange:, include_fold: false)
    assert_send_type  '() -> String',
                      normal.dup, method
    assert_send_type  '() -> nil',
                      nochange.dup, method

    options = %i[ascii lithuanian turkic] + (include_fold ? [:fold] : [])

    options.each do |option|
      assert_send_type  "(#{options.map(&:inspect).join('|')}) -> String",
                        normal.dup, method, option
      assert_send_type  "(#{options.map(&:inspect).join('|')}) -> nil",
                        nochange.dup, method, option
    end

    assert_send_type  '(:lithuanian, :turkic) -> String',
                      normal.dup, method, :lithuanian, :turkic
    assert_send_type  '(:lithuanian, :turkic) -> nil',
                      nochange.dup, method, :lithuanian, :turkic

    assert_send_type  '(:turkic, :lithuanian) -> String',
                      normal.dup, method, :turkic, :lithuanian
    assert_send_type  '(:turkic, :lithuanian) -> nil',
                      nochange.dup, method, :turkic, :lithuanian
  end

  def test_initialize
    assert_send_type  '() -> String',
                      String.allocate, :initialize

    with_string do |source|
      assert_send_type  '(string) -> String',
                        String.allocate, :initialize, source
    end

    with_encoding.and_nil do |encoding|
      assert_send_type  '(encoding: encoding?) -> String',
                        String.allocate, :initialize, encoding: encoding
    end

    with_int.and_nil do |capacity|
      assert_send_type  '(capacity: int?) -> String',
                        String.allocate, :initialize, capacity: capacity
    end
  end

  def test_initialize_copy
    test_replace(:initialize_copy)
  end

  def test_mod
    with_array 1, 2 do |ary|
      assert_send_type  '(array[untyped]) -> String',
                        '%d %d', :%, ary
    end

    with_hash a: 3, b: 4 do |named|
      assert_send_type  '(hash[Symbol, untyped]) -> String',
                        '%<a>d %<b>d', :%, named
    end

    with_untyped do |arg|
      # Our test uses `'%s'` so we need to make sure the thing can respond to it.
      def arg.to_s = "A" unless defined? arg.to_s

      assert_send_type  '(untyped) -> String',
                        '%s', :%, arg
    end
  end

  def test_mul
    with_int do |amount|
      assert_send_type  '(int) -> String',
                        'hello', :*, amount
    end
  end

  def test_add
    with_string do |str|
      assert_send_type  '(string) -> String',
                        'hello', :+, str
    end
  end

  def test_upos
    assert_send_type  '() -> String',
                      'hi'.dup, :+@ # `.dup` in case we have frozen_string_literal as we're testing `+@`

    assert_send_type  '() -> String',
                      Class.new(String).new('hi').freeze, :+@
  end

  def test_uneg(method = :-@)
    assert_send_type  '() -> String',
                      Class.new(String).new('hi'), method

    assert_send_type  '() -> String',
                      'hi'.freeze, method
  end

  def test_lshift
    assert_send_type  '(Integer) -> String',
                      +'hi', :<<, 38

    refute_send_type  '(_ToInt) -> untyped',
                      +'hi', :<<, ToInt.new(38)

    with_string do |string|
      assert_send_type  '(string) -> String',
                        +'hi', :<<, string
    end
  end

  def test_cmp
    with_string 's' do |other|
      assert_send_type  '(string) -> -1',
                        'a', :<=>, other
      assert_send_type  '(string) -> 0',
                        's', :<=>, other
      assert_send_type  '(string) -> 1',
                        'z', :<=>, other
    end

    blank = BlankSlate.new.__with_object_methods(:define_singleton_method)
    [-123, 0, 123].each do |comparison|
      blank.define_singleton_method(:<=>) do |x|
        raise '`x` must be `s`' unless 's' == x
        ret = BlankSlate.new.__with_object_methods(:define_singleton_method)
        ret.define_singleton_method(:>) { |x| comparison > x ? :some_truthy_value : nil }
        ret.define_singleton_method(:<) { |x| comparison < x ? :some_truthy_value : nil }
        ret
      end

      assert_send_type  '(untyped other) -> (-1 | 0 | 1)',
                        's', :<=>, blank
    end
  end

  def test_eq(method = :==)
    with_untyped do |other|
      assert_send_type  '(untyped) -> bool',
                        'hello', method, other
    end
  end

  def test_eqq
    test_eq :===
  end

  def test_match_op
    assert_send_type  '(Regexp) -> Integer',
                      'hello', :=~, /./
    assert_send_type  '(Regexp) -> nil',
                      'hello', :=~, /doesn't match/

    matcher = BlankSlate.new
    def matcher.=~(rhs)
      fail unless rhs == 'hello'
      :world
    end

    assert_send_type  '[T] (String::_MatchAgainst[String, T]) -> T',
                      'hello', :=~, matcher
  end

  def test_aref(method = :[])
    # (int start, ?int length) -> String?
    with_int(3) do |start|
      assert_send_type  '(int) -> String',
                        'hello, world', method, start
      assert_send_type  '(int) -> nil',
                        'q', method, start

      with_int 3 do |length|
        assert_send_type  '(int, int) -> String',
                          'hello, world', method, start, length
        assert_send_type  '(int, int) -> nil',
                          'q', method, start, length
      end
    end

    # (range[int?] range) -> String?
    with_range with_int(3).and_nil, with_int(5).and_nil do |range|
      assert_send_type  '(range[int?]) -> String',
                        'hello', method, range

      next if nil == range.begin # if the starting value is `nil`, you can't get `nil` outputs.
      assert_send_type  '(range[int?]) -> nil',
                        'hi', method, range
    end

    # (Regexp regexp, ?MatchData::capture backref) -> String?
    assert_send_type  '(Regexp) -> String',
                      'hello', method, /./
    assert_send_type  '(Regexp) -> nil',
                      'hello', method, /doesn't match/
    with_int(1).and 'a', :a do |backref|
      assert_send_type  '(Regexp, MatchData::capture) -> String',
                        'hallo', method, /(?<a>)./, backref
      assert_send_type  '(Regexp, MatchData::capture) -> nil',
                        'hallo', method, /(?<a>)doesn't match/, backref
    end

    # (String substring) -> String?
    assert_send_type  '(String) -> String',
                      'hello', method, 'hello'
    assert_send_type  '(String) -> nil',
                      'hello', method, 'does not exist'
    refute_send_type  '(_ToStr) -> untyped',
                      'hello', method, ToStr.new('e')
  end

  def test_aset
    with_string 'world' do |replacement|
      # [T < _ToStr] (int index, T replacement) -> T
      with_int(3) do |start|
        assert_send_type  '[T < _ToStr] (int, T) -> T',
                          'hello, world', :[]=, start, replacement

        # [T < _ToStr] (int start, int length, T replacement) -> T
        with_int 3 do |length|
          assert_send_type  '[T < _ToStr] (int, int, T) -> T',
                            'hello, world', :[]=, start, length, replacement
        end
      end

      # [T < _ToStr] (range[int?] range, T replacement) -> T
      with_range with_int(3).and_nil, with_int(5).and_nil do |range|
        assert_send_type  '[T < _ToStr] (range[int?] range, T replacement) -> T',
                          'hello', :[]=, range, replacement
      end

      # [T < _ToStr] (Regexp regexp, T replacement) -> T
      assert_send_type  '[T < _ToStr] (Regexp regexp, T replacement) -> T',
                        'hello', :[]=, /./, replacement

      # [T < _ToStr] (Regexp regexp, MatchData::capture backref, T replacement) -> T
      with_int(1).and 'a', :a do |backref|
        assert_send_type  '[T < _ToStr] (Regexp regexp, MatchData::capture backref, T replacement) -> T',
                          'hallo', :[]=, /(?<a>)./, backref, replacement
      end

      # [T < _ToStr] (String substring, T replacement) -> T
      assert_send_type  '[T < _ToStr] (String substring, T replacement) -> T',
                        'hello', :[]=, 'hello', replacement
      refute_send_type  '[T < _ToStr] (_ToStr, T replacement) -> untyped',
                        'hello', :[]=, ToStr.new('e'), replacement
    end
  end

  def test_ascii_only?
    assert_send_type  '() -> bool',
                      'hello', :ascii_only?
    assert_send_type  '() -> bool',
                      "hello\u{6666}", :ascii_only?
  end

  def test_b
    assert_send_type  '() -> String',
                      'hello', :b
  end

  def test_byteindex
    omit_if RUBY_VERSION < '3.2'

    with_string('e').and /e/ do |pattern|
      assert_send_type  '(Regexp | string) -> Integer',
                        'hello', :byteindex, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        'hallo', :byteindex, pattern

      with_int(1) do |offset|
        assert_send_type  '(Regexp | string, int) -> Integer',
                          'hello', :byteindex, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          'hallo', :byteindex, pattern, offset
      end
    end
  end

  def test_byterindex
    omit_if RUBY_VERSION < '3.2'

    with_string('e').and /e/ do |pattern|
      assert_send_type  '(Regexp | string) -> Integer',
                        'hello', :byterindex, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        'hallo', :byterindex, pattern

      with_int(1) do |offset|
        assert_send_type  '(Regexp | string, int) -> Integer',
                          'hello', :byterindex, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          'hallo', :byterindex, pattern, offset
      end
    end
  end

  def test_bytes
    assert_send_type  '() -> Array[Integer]',
                      'hello', :bytes
    assert_send_type  '() { (Integer) -> void } -> String',
                      'hello', :bytes do end
  end

  def test_bytesize
    assert_send_type  '() -> Integer',
                      'hello', :bytesize
  end

  def test_byteslice
    with_int 3 do |start|
      assert_send_type  '(int) -> String',
                        'hello', :byteslice, start
      assert_send_type  '(int) -> nil',
                        'q', :byteslice, start

      with_int 3 do |length|
        assert_send_type  '(int, int) -> String',
                          'hello', :byteslice, start, length
        assert_send_type  '(int, int) -> nil',
                          'q', :byteslice, start, length
      end
    end

    # TODO: | (range[int?] range) -> String?
  end

  def test_bytesplice
    omit_if(RUBY_VERSION < '3.2', 'String#bytesplice was added in 3.2')

    # In 3.3 and onwards (and backported to 3.2.16), the return type is `self`. This variable
    # is in case the test suite is run in a version under 3.2.16; tests for the variants only
    # supported in 3.3 and onwards use `self`. If we ever stop supporting 3.2, we can remove this.

    with_string ', world! :-D' do |string|
      assert_send_type  "(Integer, Integer, string) -> String",
                        +'hello', :bytesplice,  1, 2, string

      if RUBY_VERSION >= "3.3.0"
        assert_send_type  '(Integer, Integer, string, Integer, Integer) -> String',
                          +'hello', :bytesplice,  1, 2, string, 3, 4
      end

      with_range with_int(1).and_nil, with_int(2).and_nil do |range|
        assert_send_type  "(range[int?], string) -> String",
                          +'hello', :bytesplice, range, string

        if RUBY_VERSION >= '3.3.0'
          with_range with_int(3).and_nil, with_int(4).and_nil do |string_range|
            assert_send_type  '(range[int?], string, range[int?]) -> String',
                              +'hello', :bytesplice, range, string, string_range
          end
        end
      end
    end
  end

  def test_capitalize
    assert_case_method :capitalize
  end

  def test_capitalize!
    assert_case_method! :capitalize!, normal: 'hello', nochange: 'Hello'
  end

  def test_casecmp
    with_string 's' do |other|
      assert_send_type  '(string) -> -1',
                        'a', :casecmp, other
      assert_send_type  '(string) -> 1',
                        'z', :casecmp, other
      assert_send_type  '(string) -> 0',
                        's', :casecmp, other
    end

    # incompatible encodings yield nil
    with_string '😊'.force_encoding('IBM437') do |other|
      assert_send_type  '(string) -> nil',
                        '😊'.force_encoding('UTF-8'), :casecmp, other
    end

    with_untyped do |other|
      next if defined? other.to_str # omit the string cases of `with_untyped`.

      assert_send_type  '(untyped) -> nil',
                        's', :casecmp, other
    end
  end

  def test_casecmp?
    with_string 's' do |other|
      assert_send_type  '(string) -> bool',
                        'a', :casecmp?, other
      assert_send_type  '(string) -> bool',
                        'z', :casecmp?, other
      assert_send_type  '(string) -> bool',
                        's', :casecmp?, other
    end

    # incompatible encodings yield nil
    with_string '😊'.force_encoding('IBM437') do |other|
      assert_send_type  '(string) -> nil',
                        '😊'.force_encoding('UTF-8'), :casecmp?, other
    end

    with_untyped do |other|
      next if defined? other.to_str # omit the string cases of `with_untyped`.

      assert_send_type  '(untyped) -> nil',
                        's', :casecmp?, other
    end
  end

  def test_center
    with_int 10 do |width|
      assert_send_type  '(int) -> String',
                        'hello', :center, width

      with_string '&' do |padding|
        assert_send_type  '(int, string) -> String',
                          'hello', :center, width, padding
      end
    end
  end

  def test_chars
    assert_send_type  '() -> Array[String]',
                      'hello', :chars
    assert_send_type  '() { (String) -> void } -> String',
                      'hello', :chars do end
  end

  def test_chomp
    assert_send_type  '() -> String',
                      "hello\n", :chomp
    assert_send_type  '() -> String',
                      "hello", :chomp

    with_string("\n").and_nil do |separator|
      assert_send_type  '(string?) -> String',
                        "hello\n", :chomp, separator
      assert_send_type  '(string?) -> String',
                        "hello", :chomp, separator
    end
  end

  def test_chomp!
    assert_send_type  '() -> String',
                      +"hello\n", :chomp!
    assert_send_type  '() -> nil',
                      +'hello', :chomp!

    with_string(".") do |separator|
      assert_send_type  '(string) -> String',
                        +"hello.", :chomp!, separator
      assert_send_type  '(string) -> nil',
                        +"hello", :chomp!, separator
    end

    assert_send_type  '(nil) -> nil',
                      "a\n", :chomp!, nil
  end

  def test_chop
    assert_send_type  '() -> String',
                      'hello', :chop
    assert_send_type  '() -> String',
                      '', :chop
  end

  def test_chop!
    assert_send_type  '() -> String',
                      +'hello', :chop!
    assert_send_type  '() -> nil',
                      +'', :chop!
  end

  def test_chr
    assert_send_type  '() -> String',
                      'hello', :chr
  end

  def test_clear
    assert_send_type  '() -> String',
                      +'hello', :clear
  end

  def test_codepoints
    assert_send_type  '() -> Array[Integer]',
                      'hello', :codepoints
    assert_send_type  '() { (Integer) -> void } -> String',
                      'hello', :codepoints do end
  end

  def test_concat
    with_string do |str|
      assert_send_type  '(*string | Integer) -> String',
                        +'hello', :concat, str, 38
    end
  end

  def test_count
    with_string 'l' do |selector|
      assert_send_type  '(String::selector) -> Integer',
                        'hello', :count, selector
      assert_send_type  '(String::selector, *String::selector) -> Integer',
                        'hello', :count, selector, selector
    end
  end

  def test_dedup
    omit_if RUBY_VERSION < '3.2.0'
    test_uneg :dedup
  end

  def test_crypt
    with_string 'hello' do |salt|
      assert_send_type  '(string) -> String',
                        'world', :crypt, salt
    end
  end

  def test_delete
    with_string 'l' do |selector|
      assert_send_type  '(String::selector) -> String',
                        'hello', :delete, selector
      assert_send_type  '(String::selector, *String::selector) -> String',
                        'hello', :delete, selector, selector
    end
  end

  def test_delete!
    with_string 'l' do |selector|
      assert_send_type  '(String::selector) -> String',
                        +'hello', :delete!, selector
      assert_send_type  '(String::selector, *String::selector) -> String',
                        +'hello', :delete!, selector, selector

      assert_send_type  '(String::selector) -> nil',
                        +'heya', :delete!, selector
      assert_send_type  '(String::selector, *String::selector) -> nil',
                        +'heya', :delete!, selector, selector
    end
  end

  def test_delete_prefix
    with_string 'he' do |prefix|
      assert_send_type  '(string) -> String',
                        'hello', :delete_prefix, prefix
    end
  end

  def test_delete_prefix!
    with_string 'he' do |prefix|
      assert_send_type  '(string) -> String',
                        +'hello', :delete_prefix!, prefix
      assert_send_type  '(string) -> nil',
                        +'ello', :delete_prefix!, prefix
    end
  end

  def test_delete_suffix
    with_string 'lo' do |suffix|
      assert_send_type  '(string) -> String',
                        'hello', :delete_suffix, suffix
    end
  end

  def test_delete_suffix!
    with_string 'lo' do |suffix|
      assert_send_type  '(string) -> String',
                        +'hello', :delete_suffix!, suffix
      assert_send_type  '(string) -> nil',
                        +'heya', :delete_suffix!, suffix
    end
  end

  def test_downcase
    assert_case_method :downcase, include_fold: true
  end

  def test_downcase!
    assert_case_method! :downcase!, normal: 'HELLO', nochange: 'hello', include_fold: true
  end

  def test_dump
    assert_send_type  '() -> String',
                      'hello', :dump
  end

  def test_each_byte
    assert_send_type "() -> Enumerator[Integer, String]",
                     "hello", :each_byte
    assert_send_type "() { (Integer) -> void } -> String",
                     "hello", :each_byte do |c| c end
  end

  def test_each_char
    assert_send_type "() -> Enumerator[String, String]",
                     "hello", :each_char
    assert_send_type "() { (String) -> void } -> String",
                     "hello", :each_char do |c| c end
  end

  def test_each_codepoint
    assert_send_type "() -> Enumerator[Integer, String]",
                     "hello", :each_codepoint
    assert_send_type "() { (Integer) -> void } -> String",
                     "hello", :each_codepoint do |c| c end
  end

  def test_each_grapheme_cluster
    assert_send_type "() -> Enumerator[String, String]",
                     "hello", :each_grapheme_cluster
    assert_send_type "() { (String) -> void } -> String",
                     "hello", :each_grapheme_cluster do |c| c end
  end

  def test_each_line
    assert_send_type  '() -> Enumerator[String, String]',
                      "hello\nworld", :each_line
    assert_send_type  '() { (String) -> void } -> String',
                      "hello\nworld", :each_line do end

    with_string('_').and_nil do |separator|
      assert_send_type  '(string?) -> Enumerator[String, String]',
                        "hello\nworld", :each_line, separator
      assert_send_type  '(string?) { (String) -> void } -> String',
                        "hello\nworld", :each_line, separator do end

      with_boolish do |chomp|
        assert_send_type  '(string?, chomp: boolish) -> Enumerator[String, String]',
                          "hello\nworld", :each_line, separator, chomp: chomp
        assert_send_type  '(string?, chomp: boolish) { (String) -> void } -> String',
                          "hello\nworld", :each_line, separator, chomp: chomp do end
      end
    end

    with_boolish do |chomp|
      assert_send_type  '(chomp: boolish) -> Enumerator[String, String]',
                        "hello\nworld", :each_line, chomp: chomp
      assert_send_type  '(chomp: boolish) { (String) -> void } -> String',
                        "hello\nworld", :each_line, chomp: chomp do end
    end
  end

  def test_empty?
    assert_send_type '() -> bool',
                     'hello', :empty?
    assert_send_type '() -> bool',
                     '', :empty?
  end

  def test_encode
    # `encode` returns an `instance`, not a `String`, unlike most other functions.
    ruby = Class.new(String).new "Ruby\u05E2"

    assert_send_type  '() -> String',
                      ruby, :encode

    with_encoding 'UTF-8' do |source|
      assert_send_type  '(encoding) -> String',
                        ruby, :encode, source

      with_encoding 'ISO-8859-1' do |target|
        assert_send_type  '(encoding, encoding) -> String',
                          ruby, :encode, source, target
      end
    end

    # There's no real way to know (without inspecting the output of `.encode`) whether or not the
    # keyword arguments that're supplied are defined, as `.encode` (and `.encode!`) silently swallow
    # any unknown arguments. So there's no way to know for sure if tests are passing because we have
    # the correct signature, or if the arguments are unknown (and thus accepted).
    #
    # We're also going to do all keywords individually, as it's too hard to do all possible
    # combinations.

    with(:replace).and_nil do |replace|
      assert_send_type  '(invalid: :replace ?) -> String',
                        ruby, :encode, invalid: replace
      assert_send_type  '(undef: :replace ?) -> String',
                        ruby, :encode, undef: replace
                      rescue; require 'pry'; binding.pry
    end

    with_string('&').and_nil do |replace|
      assert_send_type  '(replace: string?) -> String',
                        ruby, :encode, replace: replace
    end

    with(:text, :attr).and_nil do |xml|
      assert_send_type  '(xml: (:text | :attr)?) -> String',
                        ruby, :encode, xml: xml
    end

    with(:universal, :crlf, :cr, :lf).and_nil do |newline|
      assert_send_type  '(newline: (:universal | :crlf | :cr | :lf)?) -> String',
                        ruby, :encode, newline: newline
    end

    with_boolish do |boolish|
      assert_send_type  '(universal_newline: boolish) -> String',
                        ruby, :encode, universal_newline: boolish
      assert_send_type  '(cr_newline: boolish) -> String',
                        ruby, :encode, cr_newline: boolish
      assert_send_type  '(crlf_newline: boolish) -> String',
                        ruby, :encode, crlf_newline: boolish
      assert_send_type  '(lf_newline: boolish) -> String',
                        ruby, :encode, lf_newline: boolish
    end

    iso_8859_1 = Encoding::ISO_8859_1

    test_fallback = proc do |type, &block|
      with_string('&') do |string|
        assert_send_type  "(Encoding, fallback: #{type}) -> String",
                          ruby, :encode, iso_8859_1, fallback: block.call(string)
      end

      begin
        ruby.encode iso_8859_1, fallback: block.call(nil)
      rescue Encoding::UndefinedConversionError => err
        pass '`nil` causes an error to be thrown'
      else
        flunk 'fallback of nil should cause an error'
      end
    end

    test_fallback.call '^(String) -> string?' do |string|
      ->_ignore { string }
    end

    test_fallback.call 'Method' do |string|
      bs = BlankSlate.new.__with_object_methods(:method, :define_singleton_method)
      bs.define_singleton_method(:method_name) { |_ignore| string }
      bs.method(:method_name)
    end

    test_fallback.call '::String::_EncodeFallbackAref' do |string|
      bs = BlankSlate.new.__with_object_methods(:define_singleton_method)
      bs.define_singleton_method(:[]) { |_ignore| string  }
      bs
    end
  end

  def test_encode!
    # `encode` returns an `instance`, not a `String`, unlike most other functions.
    ruby = Class.new(String).new "Ruby\u05E2"

    assert_send_type  '() -> String',
                      ruby.dup, :encode!

    with_encoding 'UTF-8' do |source|
      assert_send_type  '(encoding) -> String',
                        ruby.dup, :encode!, source

      with_encoding 'ISO-8859-1' do |target|
        assert_send_type  '(encoding, encoding) -> String',
                          ruby.dup, :encode!, source, target
      end
    end

    # There's no real way to know (without inspecting the output of `.encode`) whether or not the
    # keyword arguments that're supplied are defined, as `.encode` (and `.encode!`) silently swallow
    # any unknown arguments. So there's no way to know for sure if tests are passing because we have
    # the correct signature, or if the arguments are unknown (and thus accepted).
    #
    # We're also going to do all keywords individually, as it's too hard to do all possible
    # combinations.

    with(:replace).and_nil do |replace|
      assert_send_type  '(invalid: :replace ?) -> String',
                        ruby.dup, :encode!, invalid: replace
      assert_send_type  '(undef: :replace ?) -> String',
                        ruby.dup, :encode!, undef: replace
                      rescue; require 'pry'; binding.pry
    end

    with_string('&').and_nil do |replace|
      assert_send_type  '(replace: string?) -> String',
                        ruby.dup, :encode!, replace: replace
    end

    with(:text, :attr).and_nil do |xml|
      assert_send_type  '(xml: (:text | :attr)?) -> String',
                        ruby.dup, :encode!, xml: xml
    end

    with(:universal, :crlf, :cr, :lf).and_nil do |newline|
      assert_send_type  '(newline: (:universal | :crlf | :cr | :lf)?) -> String',
                        ruby.dup, :encode!, newline: newline
    end

    with_boolish do |boolish|
      assert_send_type  '(universal_newline: boolish) -> String',
                        ruby.dup, :encode!, universal_newline: boolish
      assert_send_type  '(cr_newline: boolish) -> String',
                        ruby.dup, :encode!, cr_newline: boolish
      assert_send_type  '(crlf_newline: boolish) -> String',
                        ruby.dup, :encode!, crlf_newline: boolish
      assert_send_type  '(lf_newline: boolish) -> String',
                        ruby.dup, :encode!, lf_newline: boolish
    end

    iso_8859_1 = Encoding::ISO_8859_1

    test_fallback = proc do |type, &block|
      with_string('&') do |string|
        assert_send_type  "(Encoding, fallback: #{type}) -> String",
                          ruby.dup, :encode!, iso_8859_1, fallback: block.call(string)
      end

      begin
        ruby.encode iso_8859_1, fallback: block.call(nil)
      rescue Encoding::UndefinedConversionError => err
        pass '`nil` causes an error to be thrown'
      else
        flunk 'fallback of nil should cause an error'
      end
    end

    test_fallback.call '^(String) -> string?' do |string|
      ->_ignore { string }
    end

    test_fallback.call 'Method' do |string|
      bs = BlankSlate.new.__with_object_methods(:method, :define_singleton_method)
      bs.define_singleton_method(:method_name) { |_ignore| string }
      bs.method(:method_name)
    end

    test_fallback.call '::String::_EncodeFallbackAref' do |string|
      bs = BlankSlate.new.__with_object_methods(:define_singleton_method)
      bs.define_singleton_method(:[]) { |_ignore| string  }
      bs
    end
  end

  def test_encoding
    assert_send_type  '() -> Encoding',
                      'hello', :encoding
  end

  def test_end_with?
    assert_send_type  '() -> bool',
                      'hello', :end_with?

    with_string 'lo' do |suffix|
      assert_send_type  '(*string) -> bool',
                        'hello', :end_with?, suffix
      assert_send_type  '(*string) -> bool',
                        'hello', :end_with?, suffix, suffix
    end
  end

  def test_eql?
    with_untyped do |other|
      assert_send_type  '(untyped) -> bool',
                        'hello', :eql?, other
    end
  end

  def test_force_encoding
    with_encoding do |encoding|
      assert_send_type  '(encoding) -> String',
                        'hello', :force_encoding, encoding
    end
  end

  def test_freeze
    assert_send_type  '() -> String',
                      'hello', :freeze
  end

  def test_getbyte
    with_int 3 do |index|
      assert_send_type  '(int) -> Integer',
                        'hello', :getbyte, index
      assert_send_type  '(int) -> nil',
                        'hi', :getbyte, index
    end
  end

  def test_grapheme_clusters
    assert_send_type  '() -> Array[String]',
                      'hello', :grapheme_clusters
    assert_send_type  '() { (String) -> void } -> String',
                      'hello', :grapheme_clusters do end
  end

  def test_gsub
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> Enumerator[String, String]',
                        'hello', :gsub, pattern
      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> String',
                        'hello', :gsub, pattern do ToS.new end

      with_string '!' do |replacement|
        assert_send_type  '(Regexp | string, string) -> String',
                          'hello', :gsub, pattern, replacement
      end

      with_hash 'l' => ToS.new('!') do |replacement|
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> String',
                          'hello', :gsub, pattern, replacement
      end
    end
  end

  def test_gsub!
    omit 'There is currently a bug that prevents `.gsub!` from being testable'

    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> Enumerator[String, String]',
                        +'hello', :gsub!, pattern
      assert_send_type  '(Regexp | string) -> Enumerator[String, String]',
                        +'heya', :gsub!, pattern

      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> String',
                        +'hello', :gsub!, pattern do ToS.new end
      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> nil',
                        +'heya', :gsub!, pattern do ToS.new end

      with_string '!' do |replacement|
        assert_send_type  '(Regexp | string, string) -> String',
                          +'hello', :gsub!, pattern, replacement
        assert_send_type  '(Regexp | string, string) -> nil',
                          +'heya', :gsub!, pattern, replacement
      end

      with_hash 'l' => ToS.new('!') do |replacement|
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> String',
                          +'hello', :gsub!, pattern, replacement
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> nil',
                          +'heya', :gsub!, pattern, replacement
      end
    end
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      'hello', :hash
  end

  def test_hex
    assert_send_type  '() -> Integer',
                      '0x12', :hex
  end

  def test_include?
    with_string 'el' do |other|
      assert_send_type  '(string) -> bool',
                        'hello', :include?, other
      assert_send_type  '(string) -> bool',
                        'heya', :include?, other
    end
  end

  def test_index
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> Integer',
                        'hello', :index, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        'heya', :index, pattern

      with_int 1 do |offset|
        assert_send_type  '(Regexp | string, int) -> Integer',
                          'hello', :index, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          'heya', :index, pattern, offset
      end
    end
  end

  def test_insert
    with_int -1 do |index|
      with_string ', world' do |string|
        assert_send_type  '(int, string) -> String',
                          'hello', :insert, index, string
      end
    end
  end

  def test_inspect
    assert_send_type  '() -> String',
                      'hello', :inspect
  end

  def test_intern(method = :intern)
    assert_send_type  '() -> Symbol',
                      'hello', method
  end

  def test_length(method = :length)
    assert_send_type  '() -> Integer',
                      'hello', method
  end

  def test_lines
    assert_send_type  '() -> Array[String]',
                      "hello\nworld", :lines
    assert_send_type  '() { (String) -> void } -> String',
                      "hello\nworld", :lines do end

    with_string('_').and_nil do |separator|
      assert_send_type  '(string?) -> Array[String]',
                        "hello\nworld", :lines, separator
      assert_send_type  '(string?) { (String) -> void } -> String',
                        "hello\nworld", :lines, separator do end

      with_boolish do |chomp|
        assert_send_type  '(string?, chomp: boolish) -> Array[String]',
                          "hello\nworld", :lines, separator, chomp: chomp
        assert_send_type  '(string?, chomp: boolish) { (String) -> void } -> String',
                          "hello\nworld", :lines, separator, chomp: chomp do end
      end
    end

    with_boolish do |chomp|
      assert_send_type  '(chomp: boolish) -> Array[String]',
                        "hello\nworld", :lines, chomp: chomp
      assert_send_type  '(chomp: boolish) { (String) -> void } -> String',
                        "hello\nworld", :lines, chomp: chomp do end
    end
  end

  def test_ljust
    with_int 10 do |width|
      assert_send_type  '(int) -> String',
                        'hello', :ljust, width

      with_string '&' do |padding|
        assert_send_type  '(int, string) -> String',
                          'hello', :ljust, width, padding
      end
    end
  end

  def test_lstrip
    assert_send_type  '() -> String',
                      ' hello', :lstrip
    assert_send_type  '() -> String',
                      'hello', :lstrip
  end

  def test_lstrip!
    assert_send_type  '() -> String',
                      +' hello', :lstrip!
    assert_send_type  '() -> nil',
                      +'hello', :lstrip!
  end

  def test_match
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> MatchData',
                        'hello', :match, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        'heya', :match, pattern

      assert_send_type  '[T] (Regexp | string) { (MatchData) -> T } -> T',
                        'hello', :match, pattern do 1r end
      assert_send_type  '[T] (Regexp | string) { (MatchData) -> T } -> nil',
                        'heya', :match, pattern do 1r end

      with_int 0 do |offset|
        assert_send_type  '(Regexp | string, int) -> MatchData',
                          'hello', :match, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          'heya', :match, pattern, offset

        assert_send_type  '[T] (Regexp | string, int) { (MatchData) -> T } -> T',
                          'hello', :match, pattern, offset do 1r end
        assert_send_type  '[T] (Regexp | string, int) { (MatchData) -> T } -> nil',
                          'heya', :match, pattern, offset do 1r end
      end
    end
  end

  def test_match?
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> bool',
                        'hello', :match?, pattern
      assert_send_type  '(Regexp | string) -> bool',
                        'heya', :match?, pattern

      with_int 0 do |offset|
        assert_send_type  '(Regexp | string, int) -> bool',
                          'hello', :match?, pattern, offset
        assert_send_type  '(Regexp | string, int) -> bool',
                          'heya', :match?, pattern, offset
      end
    end
  end

  def test_next
    test_succ :next
  end

  def test_next!
    test_succ! :next!
  end

  def test_oct
    assert_send_type  '() -> Integer',
                      '0x12', :oct
  end

  def test_ord
    assert_send_type  '() -> Integer',
                      'a', :ord
  end

  def test_partition
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> [String, String, String]',
                        'hello', :partition, pattern
      assert_send_type  '(Regexp | string) -> [String, String, String]',
                        'heya', :partition, pattern
    end
  end

  def test_prepend
    assert_send_type  '() -> String',
                      +'hello', :prepend

    with_string 'world' do |other_string|
      assert_send_type  '(*string) -> String',
                        +'hello', :prepend, other_string
      assert_send_type  '(*string) -> String',
                        +'hello', :prepend, other_string, other_string
    end
  end

  def test_replace(method = :replace)
    with_string 'world' do |string|
      assert_send_type  '(string) -> String',
                        +'hello', method, string
    end
  end

  def test_reverse
    assert_send_type  '() -> String',
                      'hello', :reverse
    assert_send_type  '() -> String',
                      '', :reverse
  end

  def test_reverse!
    assert_send_type  '() -> String',
                      +'hello', :reverse!
    assert_send_type  '() -> String',
                      +'', :reverse!
  end

  def test_rindex
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> Integer',
                        'hello', :rindex, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        'heya', :rindex, pattern

      with_int 4 do |offset|
        assert_send_type  '(Regexp | string, int) -> Integer',
                          'hello', :rindex, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          'heya', :rindex, pattern, offset
      end
    end
  end

  def test_rjust
    with_int 10 do |width|
      assert_send_type  '(int) -> String',
                        'hello', :rjust, width

      with_string '&' do |padding|
        assert_send_type  '(int, string) -> String',
                          'hello', :rjust, width, padding
      end
    end
  end

  def test_rpartition
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> [String, String, String]',
                        'hello', :rpartition, pattern
      assert_send_type  '(Regexp | string) -> [String, String, String]',
                        'heya', :rpartition, pattern
    end
  end

  def test_rstrip
    assert_send_type  '() -> String',
                      'hello ', :rstrip
    assert_send_type  '() -> String',
                      'hello', :rstrip
  end

  def test_rstrip!
    assert_send_type  '() -> String',
                      +'hello ', :rstrip!
    assert_send_type  '() -> nil',
                      +'hello', :rstrip!
  end

  def test_scan
    assert_send_type  '(Regexp) -> Array[String]',
                      'hello', :scan, /l/
    assert_send_type  '(Regexp) -> Array[Array[String]]',
                      'hello', :scan, /(l)/

    assert_send_type  '(Regexp) { (String) -> void } -> String',
                      'hello', :scan, /l/ do end
    assert_send_type  '(Regexp) { (Array[String]) -> void } -> String',
                      'hello', :scan, /(l)/ do end

    with_string 'l' do |pattern|
      assert_send_type  '(string) -> Array[String]',
                        'hello', :scan, pattern
      assert_send_type  '(string) { (String) -> void } -> String',
                        'hello', :scan, pattern do end
    end
  end

  def test_scrub
    valid = 'hello'
    invalid = "hel\x81\x81lo"

    assert_send_type  '() -> String',
                      valid, :scrub
    assert_send_type  '() -> String',
                      invalid, :scrub

    with_string '&' do |replacement|
      assert_send_type  '(string) -> String',
                        valid, :scrub, replacement
      assert_send_type  '(string) -> String',
                        invalid, :scrub, replacement
    end

    with_string '&' do |replacement|
      assert_send_type  '() { (String) -> string } -> String',
                        valid, :scrub do replacement end
      assert_send_type  '() { (String) -> string } -> String',
                        invalid, :scrub do replacement end

      assert_send_type  '(nil) { (String) -> string } -> String',
                        valid, :scrub, nil do replacement end
      assert_send_type  '(nil) { (String) -> string } -> String',
                        invalid, :scrub, nil do replacement end
    end
  end

  def test_scrub!
    valid = 'hello'
    invalid = "hel\x81\x81lo"

    assert_send_type  '() -> String',
                      valid.dup, :scrub!
    assert_send_type  '() -> String',
                      invalid.dup, :scrub!

    with_string '&' do |replacement|
      assert_send_type  '(string) -> String',
                        valid.dup, :scrub!, replacement
      assert_send_type  '(string) -> String',
                        invalid.dup, :scrub!, replacement
    end

    with_string '&' do |replacement|
      assert_send_type  '() { (String) -> string } -> String',
                        valid.dup, :scrub! do replacement end
      assert_send_type  '() { (String) -> string } -> String',
                        invalid.dup, :scrub! do replacement end

      assert_send_type  '(nil) { (String) -> string } -> String',
                        valid.dup, :scrub!, nil do replacement end
      assert_send_type  '(nil) { (String) -> string } -> String',
                        invalid.dup, :scrub!, nil do replacement end
    end
  end

  def test_setbyte
    with_int 0 do |index|
      with_int 38 do |byte|
        assert_send_type  '[T < _ToStr] (int, T) -> T',
                          +'hello', :setbyte, index, byte
      end
    end
  end

  def test_size
    test_length :size
  end

  def test_slice
    test_aref :slice
  end

  def test_slice!
    # (int start, ?int length) -> String?
    with_int(3) do |start|
      assert_send_type  '(int) -> String',
                        +'hello, world', :slice!, start
      assert_send_type  '(int) -> nil',
                        +'hi', :slice!, start

      with_int 3 do |length|
        assert_send_type  '(int, int) -> String',
                          +'hello, world', :slice!, start, length
        assert_send_type  '(int, int) -> nil',
                          +'q', :slice!, start, length
      end
    end

    # (range[int?] range) -> String?
    with_range with_int(3).and_nil, with_int(5).and_nil do |range|
      assert_send_type  '(range[int?]) -> String',
                        +'hello', :slice!, range

      next if nil == range.begin # if the starting value is `nil`, you can't get `nil` outputs.
      assert_send_type  '(range[int?]) -> nil',
                        +'hi', :slice!, range
    end

    # (Regexp regexp, ?MatchData::capture backref) -> String?
    assert_send_type  '(Regexp) -> String',
                      +'hello', :slice!, /./
    assert_send_type  '(Regexp) -> nil',
                      +'hello', :slice!, /doesn't match/
    with_int(1).and 'a', :a do |backref|
      assert_send_type  '(Regexp, MatchData::capture) -> String',
                        +'hallo', :slice!, /(?<a>)./, backref
      assert_send_type  '(Regexp, MatchData::capture) -> nil',
                        +'hallo', :slice!, /(?<a>)doesn't match/, backref
    end

    # (String substring) -> String?
    assert_send_type  '(String) -> String',
                      +'hello', :slice!, 'hello'
    assert_send_type  '(String) -> nil',
                      +'hello', :slice!, 'does not exist'
    refute_send_type  '(_ToStr) -> untyped',
                      +'hello', :slice!, ToStr.new('e')
  end

  def test_split
    with_string('l').and nil, /l/ do |pattern|
      assert_send_type  '(Regexp | string | nil) -> Array[String]',
                        'hello', :split, pattern
      assert_send_type  '(Regexp | string | nil) { (String) -> void } -> String',
                        'hello', :split, pattern do end

      assert_send_type  '(Regexp | string | nil) -> Array[String]',
                        'heya', :split, pattern
      assert_send_type  '(Regexp | string | nil) { (String) -> void } -> String',
                        'heya', :split, pattern do end

      with_int 3 do |limit|
        assert_send_type  '(Regexp | string | nil, int) -> Array[String]',
                          'hello', :split, pattern, limit
        assert_send_type  '(Regexp | string | nil, int) { (String) -> void } -> String',
                          'hello', :split, pattern, limit do end

        assert_send_type  '(Regexp | string | nil, int) -> Array[String]',
                          'heya', :split, pattern, limit
        assert_send_type  '(Regexp | string | nil, int) { (String) -> void } -> String',
                          'heya', :split, pattern, limit do end
      end
    end
  end

  def test_squeeze
    assert_send_type  '() -> String',
                      'hello', :squeeze

    with_string 'l' do |selector|
      assert_send_type  '(*String::selector) -> String',
                        'hello', :squeeze, selector
      assert_send_type  '(*String::selector) -> String',
                        'hello', :squeeze, selector, selector
    end
  end

  def test_squeeze!
    assert_send_type  '() -> String',
                      +'hello', :squeeze!
    assert_send_type  '() -> nil',
                      +'heya', :squeeze!

    with_string 'l' do |selector|
      assert_send_type  '(*String::selector) -> String',
                        +'hello', :squeeze!, selector
      assert_send_type  '(*String::selector) -> String',
                        +'hello', :squeeze!, selector, selector

      assert_send_type  '(*String::selector) -> nil',
                        +'heya', :squeeze!, selector
      assert_send_type  '(*String::selector) -> nil',
                        +'heya', :squeeze!, selector, selector
    end
  end


  def test_start_with?
    assert_send_type  '() -> bool',
                      'hello', :start_with?

    with_string('he').and /he/ do |prefix|
      assert_send_type  '(*string | Regexp) -> bool',
                        'hello', :start_with?, prefix
      assert_send_type  '(*string | Regexp) -> bool',
                        'hello', :start_with?, prefix, prefix
    end
  end

  def test_strip
    assert_send_type  '() -> String',
                      ' hello ', :strip
    assert_send_type  '() -> String',
                      'hello', :strip
  end

  def test_strip!
    assert_send_type  '() -> String',
                      ' hello ', :strip!
    assert_send_type  '() -> nil',
                      'hello', :strip!
  end

  def test_sub
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> String',
                        'hello', :sub, pattern do ToS.new end

      with_string '!' do |replacement|
        assert_send_type  '(Regexp | string, string) -> String',
                          'hello', :sub, pattern, replacement
      end

      with_hash 'l' => ToS.new('!') do |replacement|
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> String',
                          'hello', :sub, pattern, replacement
      end
    end
  end

  def test_sub!
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> String',
                        'hello', :sub!, pattern do ToS.new end
      assert_send_type  '(Regexp | string) { (String) -> _ToS } -> nil',
                        'heya', :sub!, pattern do ToS.new end

      with_string '!' do |replacement|
        assert_send_type  '(Regexp | string, string) -> String',
                          'hello', :sub!, pattern, replacement
        assert_send_type  '(Regexp | string, string) -> nil',
                          'heya', :sub!, pattern, replacement
      end

      with_hash 'l' => ToS.new('!') do |replacement|
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> String',
                          'hello', :sub!, pattern, replacement
        assert_send_type  '(Regexp | string, hash[String, _ToS]) -> nil',
                          'heya', :sub!, pattern, replacement
      end
    end
  end

  def test_succ(method = :succ)
    assert_send_type  '() -> String',
                      'hello', method
  end

  def test_succ!(method = :succ!)
    assert_send_type  '() -> String',
                      'hello', method
    assert_send_type  '() -> String',
                      '', method
  end

  def test_sum
    assert_send_type  '() -> Integer',
                      'hello', :sum

    with_int 15 do |bits|
      assert_send_type  '(int) -> Integer',
                        'hello', :sum, bits
    end
  end

  def test_swapcase
    assert_case_method :swapcase
  end

  def test_swapcase!
    assert_case_method! :swapcase!, normal: 'HeLlO', nochange: '0123'
  end

  def test_to_c
    assert_send_type  '() -> Complex',
                      'hello', :to_c
    assert_send_type  '() -> Complex',
                      '1159710911210111411597110100', :to_c
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      'hello', :to_f
    assert_send_type  '() -> Float',
                      '1159710911210111411597110100', :to_f
  end

  def test_to_i
    assert_send_type  '() -> Integer',
                      'hello', :to_i
    assert_send_type  '() -> Integer',
                      '1159710911210111411597110100', :to_i
  end

  def test_to_r
    assert_send_type  '() -> Rational',
                      'hello', :to_r
    assert_send_type  '() -> Rational',
                      '1159710911210111411597110100', :to_r
  end

  def test_to_s(method = :to_s)
    assert_send_type  '() -> String',
                      'hello', method
    assert_send_type  '() -> String',
                      Class.new(String).new('hello'), method
  end

  def test_to_str
    test_to_s :to_str
  end

  def test_to_sym
    test_intern :to_sym
  end

  def test_tr
    with_string 'aeiouy' do |source|
      with_string '-' do |replacement|
        assert_send_type  '(string, string) -> String',
                          'hello', :tr, source, replacement
      end
    end
  end

  def test_tr!
    with_string 'aeiouy' do |source|
      with_string '-' do |replacement|
        assert_send_type  '(string, string) -> String',
                          +'hello', :tr!, source, replacement
        assert_send_type  '(string, string) -> nil',
                          +'crwth', :tr!, source, replacement # fun fact: crwth is a word.
      end
    end
  end

  def test_tr_s
    with_string 'aeiouy' do |source|
      with_string '-' do |replacement|
        assert_send_type  '(string, string) -> String',
                          'hello', :tr_s, source, replacement
      end
    end
  end

  def test_tr_s!
    with_string 'aeiouy' do |source|
      with_string '-' do |replacement|
        assert_send_type  '(string, string) -> String',
                          +'hello', :tr_s!, source, replacement
        assert_send_type  '(string, string) -> nil',
                          +'crwth', :tr_s!, source, replacement # fun fact: crwth is a word.
      end
    end
  end

  def test_undump
    assert_send_type  '() -> String',
                      'hello'.dump, :undump
  end

  def test_unicode_normalize
    assert_send_type  '() -> String',
                      'a'.encode('ASCII'), :unicode_normalize

    assert_send_type  '() -> String',
                      "\u00E0", :unicode_normalize

    %i[nfc nfd nfkc nfkd].each do |form|
      assert_send_type  '(:nfc | :nfd | :nfkc | :nfkd) -> String',
                        "\u00E0", :unicode_normalize, form
      assert_send_type  '(:nfc | :nfd | :nfkc | :nfkd) -> String',
                        'a'.encode('ASCII'), :unicode_normalize, form
    end
  end

  def test_unicode_normalize!
    assert_send_type  '() -> String',
                      +"\u00E0", :unicode_normalize!

    %i[nfc nfd nfkc nfkd].each do |form|
      assert_send_type  '(:nfc | :nfd | :nfkc | :nfkd) -> String',
                        +"\u00E0", :unicode_normalize!, form
    end
  end

  def test_unicode_normalized?
    assert_send_type  '() -> bool',
                      "\u00E0", :unicode_normalized?

    %i[nfc nfd nfkc nfkd].each do |form|
      assert_send_type  '(:nfc | :nfd | :nfkc | :nfkd) -> bool',
                        "\u00E0", :unicode_normalized?, form
    end
  end

  def test_unpack
    packed = [0, 1.0, 'hello', 'p'].pack('IFA*P')

    with_string 'IFA*P' do |template|
      assert_send_type  '(string) -> Array[Integer | Float | String | nil]',
                        packed, :unpack, template
      assert_send_type  '(string) { (Integer | Float | String | nil) -> void } -> nil',
                        packed, :unpack, template do end

      next if RUBY_VERSION < '3.1'

      with_int 0 do |offset|
        assert_send_type  '(string, offset: int) -> Array[Integer | Float | String | nil]',
                          packed, :unpack, template, offset: offset
        assert_send_type  '(string, offset: int) { (Integer | Float | String | nil) -> void } -> nil',
                          packed, :unpack, template, offset: offset do end
      end
    end
  end

  def test_unpack1
    [[0, 'I', 'Integer'], [1.0, 'F', 'Float'], ['hello', 'A*', 'String'], [nil, 'P', 'nil']].each do |value, template, type|
      packed = [value].pack template

      with_string template do |template_string|
        assert_send_type  "(string) -> #{type}",
                          packed, :unpack1, template_string

        next if RUBY_VERSION < '3.1'

        with_int 0 do |offset|
          assert_send_type  "(string, offset: int) -> #{type}",
                            packed, :unpack1, template_string, offset: offset
        end
      end
    end
  end

  def test_upcase
    assert_case_method :upcase
  end

  def test_upcase!
    assert_case_method! :upcase!, normal: 'hello', nochange: 'HELLO'
  end

  def test_upto
    with_string 'z' do |endpoint|
      assert_send_type  '(string) -> Enumerator[String, String]',
                        'a', :upto, endpoint
      assert_send_type  '(string) { (String) -> void } -> String',
                        'a', :upto, endpoint do end

      with_boolish do |exclude_end|
        assert_send_type  '(string, boolish) -> Enumerator[String, String]',
                          'a', :upto, endpoint, exclude_end
        assert_send_type  '(string, boolish) { (String) -> void } -> String',
                          'a', :upto, endpoint, exclude_end do end
      end
    end
  end

  def test_valid_encoding?
    assert_send_type  '() -> bool',
                      'hello', :valid_encoding?
    assert_send_type  '() -> bool',
                      "\xc2".force_encoding("UTF-8"), :valid_encoding?
  end
end
