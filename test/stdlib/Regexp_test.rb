require_relative 'test_helper'

class RegexpSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Regexp)'

  def test_TimeoutError
    assert Regexp::TimeoutError.superclass.equal?(RegexpError)
  end

  def test_EXTENDED
    assert_const_type 'Integer',
                      'Regexp::EXTENDED'
  end

  def test_FIXEDENCODING
    assert_const_type 'Integer',
                      'Regexp::FIXEDENCODING'
  end

  def test_IGNORECASE
    assert_const_type 'Integer',
                      'Regexp::IGNORECASE'
  end

  def test_MULTILINE
    assert_const_type 'Integer',
                      'Regexp::MULTILINE'
  end

  def test_NOENCODING
    assert_const_type 'Integer',
                      'Regexp::NOENCODING'
  end

  def test_compile
    assert_send_type  '(Regexp) -> Regexp',
                      Regexp, :compile, /a/

    with_float(12.34).and_nil do |timeout|
      assert_send_type  '(Regexp, timeout: _ToF?) -> Regexp',
                        Regexp, :compile, /a/, timeout: timeout
    end

    with_string 'a' do |pattern|
      assert_send_type  '(string) -> Regexp',
                        Regexp, :compile, pattern

      with_int(Regexp::IGNORECASE).and with_string('i'), true, false, nil do |options|
        assert_send_type  '(string, int | string | bool | nil) -> Regexp',
                          Regexp, :compile, pattern, options

        # In older versions of ruby, `Regexp.{new,compile}` could take an additional third argument,
        # which indicated "no encoding". Due to weirdnesses with how keyword arguments are passed
        # around in Ruby, along with how `compile` is registered internally, the `timeout: _ToF?`
        # argument is interpreted as this optional third argument in older versions. So, to prevent
        # any issues, this `next` skips it. Note that this issue doesn't occur in `test_initialize`
        # because the implicit argument passing isn't done.
        next if RUBY_VERSION < '3.3'

        with_float(12.34).and_nil do |timeout|
          assert_send_type  '(string, int | string | bool | nil, timeout: _ToF?) -> Regexp',
                            Regexp, :compile, pattern, options, timeout: timeout
        end
      end
    end
  end

  def test_escape(method: :escape)
    with_interned 'hello.world!\K!' do |str|
      assert_send_type  '(interned) -> String',
                        Regexp, method, str
    end
  end

  def test_last_match
    # We can't use `assert_send_type` as `Regexp.last_match` depends on the current function's stackframe.
    assert_type 'nil',
                Regexp.last_match

    /(?<a>a)(?<b>b)?/ =~ 'a'
    assert_type 'MatchData',
                Regexp.last_match

    with_int(1).and :a, 'a' do |capture|
      assert_type 'String',
                  Regexp.last_match(capture)
    end

    with_int(2).and :b, 'b' do |capture|
      assert_type 'nil',
                  Regexp.last_match(capture)
    end
  end

  def test_linear_time?
    assert_send_type  '(Regexp) -> bool',
                      Regexp, :linear_time?, /(.+)++/

    assert_send_type  '(Regexp, nil) -> bool',
                      Regexp, :linear_time?, /(.+)++/, nil
    
    with_untyped do |timeout|
      assert_send_type  '(Regexp, timeout: untyped) -> bool',
                        Regexp, :linear_time?, /(.+)++/, timeout: timeout

      assert_send_type  '(Regexp, nil, timeout: untyped) -> bool',
                        Regexp, :linear_time?, /(.+)++/, nil, timeout: timeout
    end

    with_string '(.+)++' do |regexp|
      assert_send_type  '(string) -> bool',
                        Regexp, :linear_time?, regexp

      with_untyped do |timeout|
        assert_send_type  '(string, timeout: untyped) -> bool',
                          Regexp, :linear_time?, regexp, timeout: timeout
      end

      with_int(Regexp::IGNORECASE).and(with_string('i'), true, false, nil) do |options|
        assert_send_type  '(string, int | string | bool | nil) -> bool',
                          Regexp, :linear_time?, regexp, options
        
        with_untyped do |timeout|
          assert_send_type  '(string, int | string | bool | nil, timeout: untyped) -> bool',
                            Regexp, :linear_time?, regexp, options, timeout: timeout
        end
      end
    end
  end

  def test_quote
    test_escape(method: :quote)
  end

  def test_try_convert
    assert_send_type  '(Regexp) -> Regexp',
                      Regexp, :try_convert, /regexp/

    def (toregexp = BlankSlate.new).to_regexp = /a/
    assert_send_type  '(Regexp::_ToRegexp) -> Regexp',
                      Regexp, :try_convert, toregexp

    with_untyped.but Regexp, proc{!defined? _1.to_regexp} do |untyped|
      assert_send_type  '(untyped) -> nil',
                        Regexp, :try_convert, untyped
    end
  end

  def test_timeout
    omit_if RUBY_VERSION < '3.2'

    begin
      old_timeout = Regexp.timeout

      Regexp.timeout = nil
      assert_send_type  '() -> nil',
                        Regexp, :timeout

      Regexp.timeout = 1.3
      assert_send_type  '() -> Float',
                        Regexp, :timeout
    ensure
      Regexp.timeout = old_timeout
    end
  end

  def test_timeout=
    omit_if RUBY_VERSION < '3.2'

    begin
      old_timeout = Regexp.timeout

      assert_send_type  '(nil) -> nil',
                        Regexp, :timeout=, nil

      with_float 1.2 do |timeout|
        assert_send_type  '[T < _ToF] (T) -> T',
                          Regexp, :timeout=, timeout
      end
    ensure
      Regexp.timeout = old_timeout
    end
  end

  def test_union
    assert_send_type  '() -> Regexp',
                      Regexp, :union

    assert_send_type  '(Symbol) -> Regexp',
                      Regexp, :union, :&
    assert_send_type  '([Symbol]) -> Regexp',
                      Regexp, :union, [:&]

    def (toregexp = BlankSlate.new).to_regexp = /a/
    with_string 'b' do |string|
      assert_send_type  '(*Regexp::_ToRegexp | string) -> Regexp',
                        Regexp, :union, string, toregexp, string

      with_array string, toregexp, string do |array|
        assert_send_type  '(array[Regexp::_ToRegexp | string]) -> Regexp',
                          Regexp, :union, array
      end
    end
  end

  def test_new
    assert_send_type  '(Regexp) -> Regexp',
                      Regexp, :new, /a/

    with_float(12.34).and_nil do |timeout|
      assert_send_type  '(Regexp, timeout: _ToF?) -> Regexp',
                        Regexp, :new, /a/, timeout: timeout
    end

    with_string 'a' do |pattern|
      assert_send_type  '(string) -> Regexp',
                        Regexp, :new, pattern

      with_int(Regexp::IGNORECASE).and with_string('i'), true, false, nil do |options|
        assert_send_type  '(string, int | string | bool | nil) -> Regexp',
                          Regexp, :new, pattern, options

        with_float(12.34).and_nil do |timeout|
          assert_send_type  '(string, int | string | bool | nil, timeout: _ToF?) -> Regexp',
                            Regexp, :new, pattern, options, timeout: timeout
        end
      end
    end
  end

end

class RegexpInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Regexp'

  def test_initialize_copy
    assert_send_type  '(Regexp) -> Regexp',
                      Regexp.allocate, :initialize_copy, /a/
  end

  def test_eq(method: :==)
    with_untyped do |rhs|
      assert_send_type  '(untyped) -> bool',
                        /a/, method, rhs
    end
  end

  def test_eqq
    with_untyped do |rhs|
      assert_send_type  '(untyped) -> bool',
                        /a/, :===, rhs
    end
  end

  def test_matchop
    assert_send_type  '(nil) -> nil',
                      /a/, :=~, nil

    with_interned 'a' do |str|
      assert_send_type  '(interned) -> Integer',
                        /a/, :=~, str
      assert_send_type  '(interned) -> nil',
                        /b/, :=~, str
    end
  end

  def test_casefold?
    assert_send_type  '() -> bool',
                      /a/, :casefold?
    assert_send_type  '() -> bool',
                      /a/i, :casefold?
  end

  def test_encoding
    assert_send_type  '() -> Encoding',
                      /a/, :encoding
  end

  def test_eql?
    test_eq(method: :==)
  end

  def test_fixed_encoding?
    assert_send_type  '() -> bool',
                      /a/, :fixed_encoding?
    assert_send_type  '() -> bool',
                      /a/u, :fixed_encoding?
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      /a/, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      /a/, :inspect
  end

  def test_match
    with_interned 'a' do |str|
      assert_send_type  '(interned) -> MatchData',
                        /a/, :match, str
      assert_send_type  '(interned) -> nil',
                        /b/, :match, str
      assert_send_type  '[T] (interned) { (MatchData) -> T } -> T',
                        /a/, :match, str do 1r end
      assert_send_type  '[T] (interned) { (MatchData) -> T } -> nil',
                        /b/, :match, str do 1r end
     
      with_int 0 do |offset|
        assert_send_type  '(interned, int) -> MatchData',
                          /a/, :match, str, offset
        assert_send_type  '(interned, int) -> nil',
                          /b/, :match, str, offset
        assert_send_type  '[T] (interned, int) { (MatchData) -> T } -> T',
                          /a/, :match, str, offset do 1r end
        assert_send_type  '[T] (interned, int) { (MatchData) -> T } -> nil',
                          /b/, :match, str, offset do 1r end
      end
    end

    assert_send_type  '(nil) -> nil',
                      /a/, :match, nil
    assert_send_type  '(nil) { (MatchData) -> void } -> nil',
                      /a/, :match, nil do end

    with_int 0 do |offset|
      assert_send_type  '(nil, int) -> nil',
                        /a/, :match, nil, offset
      assert_send_type  '(nil, int) { (MatchData) -> void } -> nil',
                        /a/, :match, nil, offset do end
    end
  end

  def test_match?
    with_interned 'a' do |str|
      assert_send_type  '(interned) -> true',
                        /a/, :match?, str
      assert_send_type  '(interned) -> false',
                        /b/, :match?, str
     
      with_int 0 do |offset|
        assert_send_type  '(interned, int) -> true',
                          /a/, :match?, str, offset
        assert_send_type  '(interned, int) -> false',
                          /b/, :match?, str, offset
      end
    end

    assert_send_type  '(nil) -> false',
                      /a/, :match?, nil

    with_int 0 do |offset|
      assert_send_type  '(nil, int) -> false',
                        /a/, :match?, nil, offset
    end
  end

  def test_named_captures
    assert_send_type  '() -> Hash[String, Array[Integer]]',
                      /(.)/, :named_captures
    assert_send_type  '() -> Hash[String, Array[Integer]]',
                      /(?<a>.)(?<a>.)(?<b>.)/, :named_captures
  end

  def test_names
    assert_send_type  '() -> Array[String]',
                      /(.)/, :names
    assert_send_type  '() -> Array[String]',
                      /(?<a>.)(?<a>.)(?<b>.)/, :names
  end

  def test_options
    assert_send_type  '() -> Integer',
                      /a/euiosxnm, :options # _all_ the options! haha
  end

  def test_source
    assert_send_type  '() -> String',
                      /a/, :source
  end

  def test_to_s
    assert_send_type  '() -> String',
                      /a/, :to_s
  end

  def test_timeout
    assert_send_type  '() -> nil',
                      /a/, :timeout
    assert_send_type  '() -> Float',
                      Regexp.new('a', timeout: 1.3), :timeout
  end

  def test_matchop2
    # Since `$_` is function-local, you cant use `assert_send_type` here.

    $_ = 'a'
    assert_type 'Integer',
                ~/a/

    $_ = 'b'
    assert_type 'nil',
                ~/a/
  end
end
