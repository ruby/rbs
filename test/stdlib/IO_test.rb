require_relative "test_helper"
require 'tempfile'

require "io/wait"

module IOTestHelper
  def verify_encoding_options(arg_types:, return_type:, args:)
    # ensure each of the options work
    with_string.and_nil do |replace|
      assert_send_type  "(#{arg_types}, replace: string?) -> #{return_type}",
                        *args, replace: replace
    end

    fallback_object = BlankSlate.new.__with_object_methods(:method)
    def fallback_object.[](x) = nil # `[]`  just need to exist for the test
    with proc{}, fallback_object, fallback_object.method(:[]) do |fallback|
      assert_send_type  "(#{arg_types}, fallback: Proc | Method | Encoding::_EncodeFallbackAref) -> #{return_type}",
                        *args, fallback: fallback
    end

    # econv_opts; checks for `replace` being nil/nonnil
    with :replace, nil do |replace|
      assert_send_type  "(#{arg_types}, invalid: :replace | nil, undef: :replace | nil) -> #{return_type}",
                        *args, invalid: replace, undef: replace
    end

    with :text, :attr, nil do |xml|
      assert_send_type  "(#{arg_types}, xml: :text | :attr | nil) -> #{return_type}",
                        *args, xml: xml
    end

    with :universal, :crlf, :cr, :lf, nil do |newline|
      assert_send_type  "(#{arg_types}, newline: :universal | :crlf | :cr | :lf | nil) -> #{return_type}",
                        *args, newline: newline
    end

    with_boolish do |boolish|
      assert_send_type  "(#{arg_types}, universal_newline: boolish) -> #{return_type}",
                        *args, universal_newline: boolish
      assert_send_type  "(#{arg_types}, crlf_newline: boolish) -> #{return_type}",
                        *args, crlf_newline: boolish
      assert_send_type  "(#{arg_types}, cr_newline: boolish) -> #{return_type}",
                        *args, cr_newline: boolish
      assert_send_type  "(#{arg_types}, lf_newline: boolish) -> #{return_type}",
                        *args, lf_newline: boolish
    end
  end
end

class IOSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::IO)"

  def test_binread
    assert_send_type "(String) -> String",
                     IO, :binread, File.expand_path(__FILE__)
    assert_send_type "(String, Integer) -> String",
                     IO, :binread, File.expand_path(__FILE__), 3
    assert_send_type "(String, Integer, Integer) -> String",
                     IO, :binread, File.expand_path(__FILE__), 3, 0
  end

  def test_binwrite
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "some_file")
      content = "foo"

      assert_send_type "(String, String) -> Integer",
                       IO, :binwrite, filename, content
      assert_send_type "(String, String, Integer) -> Integer",
                       IO, :binwrite, filename, content, 0
      assert_send_type "(String, String, mode: String) -> Integer",
                       IO, :binwrite, filename, content, mode: "a"
      assert_send_type "(String, String, Integer, mode: String) -> Integer",
                       IO, :binwrite, filename, content, 0, mode: "a"
    end
  end

  def test_open
    Dir.mktmpdir do |dir|
      assert_send_type "(Integer) -> IO",
                       IO, :open, IO.sysopen(File.expand_path(__FILE__))
      assert_send_type "(ToInt, String) -> IO",
                       IO, :open, ToInt.new(IO.sysopen(File.expand_path(__FILE__))), "r"
      assert_send_type "(Integer) { (IO) -> Integer } -> Integer",
                       IO, :open, IO.sysopen(File.expand_path(__FILE__)), &proc {|io| io.read.size }

      assert_send_type(
        "(ToInt, path: String) -> IO",
        IO, :open, ToInt.new(IO.sysopen(File.expand_path(__FILE__))), path: "<<TEST>>"
      )
    end
  end

  def ruby
    ENV["RUBY"] || RbConfig.ruby
  end

  def test_popen
    with_string("#{ruby} -v") do |command|
      assert_send_type(
        "(string) { (IO) -> nil } -> nil",
        IO, :popen, command, &proc { nil }
      )

      assert_send_type(
        "(Hash[String, String], string) { (IO) -> nil } -> nil",
        IO, :popen, { "RUBYOPT" => "-I lib" }, command, &proc { nil }
      )
    end

    with_string("ruby") do |ruby|
      with_array(ruby, "-v") do |cmd|
        assert_send_type(
          "(array[string]) { (IO) -> nil } -> nil",
          IO, :popen, cmd, &proc { nil }
        )

        assert_send_type(
          "(Hash[String, String], array[string]) { (IO) -> nil } -> nil",
          IO, :popen, { "RUBYOPT" => "-I lib" }, cmd, &proc { nil }
        )
      end
    end
  end

  def test_copy_stream
    Dir.mktmpdir do |dir|
      src_name = File.join(dir, "src_file").tap { |f| IO.write(f, "foo") }
      dst_name = File.join(dir, "dst_file")

      assert_send_type "(String, String) -> Integer",
                       IO, :copy_stream, src_name, dst_name
      assert_send_type "(String, String, Integer) -> Integer",
                       IO, :copy_stream, src_name, dst_name, 1
      assert_send_type "(String, String, Integer, Integer) -> Integer",
                       IO, :copy_stream, src_name, dst_name, 1, 0

      File.open(dst_name, "w") do |dst_io|
        assert_send_type "(String, IO) -> Integer",
                         IO, :copy_stream, src_name, dst_io
        assert_send_type "(String, IO, Integer) -> Integer",
                         IO, :copy_stream, src_name, dst_io, 1
        assert_send_type "(String, IO, Integer, Integer) -> Integer",
                         IO, :copy_stream, src_name, dst_io, 1, 0
      end

      File.open(src_name) do |src_io|
        assert_send_type "(IO, String) -> Integer",
                         IO, :copy_stream, src_io, dst_name
        assert_send_type "(IO, String, Integer) -> Integer",
                         IO, :copy_stream, src_io, dst_name, 1
        assert_send_type "(IO, String, Integer, Integer) -> Integer",
                         IO, :copy_stream, src_io, dst_name, 1, 0
      end

      File.open(src_name) do |src_io|
        File.open(dst_name, "w") do |dst_io|
          assert_send_type "(IO, IO) -> Integer",
                           IO, :copy_stream, src_io, dst_io
          assert_send_type "(IO, IO, Integer) -> Integer",
                           IO, :copy_stream, src_io, dst_io, 1
          assert_send_type "(IO, IO, Integer, Integer) -> Integer",
                           IO, :copy_stream, src_io, dst_io, 1, 0
        end
      end
    end
  end

  def test_new
    IO.sysopen(File.expand_path(__FILE__)).tap do |fd|
      assert_send_type(
        "(Integer) -> IO",
        IO, :new, fd
      )
    end

    IO.sysopen(File.expand_path(__FILE__)).tap do |fd|
      assert_send_type(
        "(ToInt, ToStr, path: ToStr) -> IO",
        IO, :new, ToInt.new(fd), ToStr.new("r"), path: ToStr.new("<<TEST>>")
      )
    end

    IO.sysopen(File.expand_path(__FILE__)).tap do |fd|
      assert_send_type(
        "(Integer, path: nil) -> IO",
        IO, :new, fd, path: nil
      )
    end
  end

  def test_select
    if_ruby "3.0.0"..."3.2.0" do
      with_timeout.and_nil do |timeout|
        r, w = IO.pipe
        assert_send_type "(Array[IO], nil, nil, Time::_Timeout?) -> nil",
          IO, :select, [r], nil, nil, timeout
        assert_send_type "(nil, Array[IO]) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, nil, [w]
        assert_send_type "(nil, Array[IO], Array[IO]) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, nil, [w], [r]
        assert_send_type "(nil, Array[IO], Array[IO], Time::_Timeout?) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, nil, [w], [r], timeout
        w.write("x")
        assert_send_type "(Array[IO], nil, nil, Time::_Timeout?) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, [r], nil, nil, timeout
        assert_send_type "(Array[IO], nil, nil, nil) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, [r], nil, nil, nil
        assert_send_type "(Array[IO], Array[IO]) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, [r], [w]
        assert_send_type "(Array[IO], Array[IO], Array[IO]) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, [r], [w], [r]
        assert_send_type "(Array[IO], Array[IO], Array[IO], Time::_Timeout?) -> [Array[IO], Array[IO], Array[IO]]",
          IO, :select, [r], [w], [r], timeout
      ensure
        r.close
        w.close
      end
    end
  end
end

class IOInstanceTest < Test::Unit::TestCase
  include TestHelper
  include IOTestHelper

  testing '::IO'

  def open_io(path, mode:, **kw)
    io = IO.new(IO.sysopen(path, mode), mode, **kw)
    yield io
  ensure
    io.close
  end

  SMALL_TEXT_FILE = File.join(__dir__, 'util', 'small-file.txt')

  def open_read(path: SMALL_TEXT_FILE, **k, &b) = open_io(path, mode: 'r', **k, &b)
  def open_write(**k, &b) = open_io(File::NULL, mode: 'w', **k, &b)
  def open_either(**k, &b) = open_io(File::NULL, mode: 'r', **k, &b)

  def with_open_mode(mode = :read, &block)
    case mode
    when :read
      with_string('r', &block)
      with_int(File::Constants::RDONLY, &block)
    when :write
      with_string('w', &block)
      with_int(File::Constants::WRONLY, &block)
    else
      raise ArgumentError, "unknown mode `#{mode.inspect}`"
    end

    block.call(nil)
  end

  def test_initialize
    stdinfd = STDIN.fileno
    with_int stdinfd do |fd|
      assert_send_type  '(int) -> IO',
                        IO.allocate, :initialize, fd
      assert_send_type  '(int) -> IO',
                        IO.allocate, :initialize, fd

      with_open_mode do |mode|
        assert_send_type  '(int, IO::open_mode) -> IO',
                          IO.allocate, :initialize, fd, mode
        assert_send_type  '(int, IO::open_mode) -> IO',
                          IO.allocate, :initialize, fd, mode
      end
    end

    # just test each option individually for efficiency. The comments are which C functions
    # the flags come from, to keep things organized

    # rb_io_initialize:
    with_boolish do |boolish|
      assert_send_type  '(int, autoclose: boolish) -> IO',
                        IO.allocate, :initialize, stdinfd, autoclose: boolish
    end

    if RUBY_VERSION > '3.2'
      with_string.and_nil do |path|
        assert_send_type  '(int, path: string?) -> IO',
                          IO.allocate, :initialize, stdinfd, path: path
      end
    end

    # rb_io_extract_modeenc:
    with_open_mode do |mode|
      assert_send_type  '(int, mode: IO::open_mode) -> IO',
                        IO.allocate, :initialize, stdinfd, mode: mode
    end

    with_int(File::Constants::RDONLY).and_nil do |flags|
      assert_send_type  '(int, flags: int?) -> IO',
                        IO.allocate, :initialize, stdinfd, flags: flags
    end

    # extract_binmode:
    with_boolish do |boolish|
      assert_send_type  '(int, textmode: boolish) -> IO',
                        IO.allocate, :initialize, stdinfd, textmode: boolish
      assert_send_type  '(int, binmode: boolish) -> IO',
                        IO.allocate, :initialize, stdinfd, binmode: boolish
    end

    # rb_io_extract_encoding_option:
    with_encoding.and_nil do |enc|
      assert_send_type  '(int, encoding: encoding?) -> IO',
                        IO.allocate, :initialize, stdinfd, encoding: enc
      assert_send_type  '(int, external_encoding: encoding?, internal_encoding: encoding?) -> IO',
                        IO.allocate, :initialize, stdinfd, external_encoding: enc, internal_encoding: enc
    end

    verify_encoding_options(
      arg_types: 'int',
      return_type: 'IO',
      args: [IO.allocate, :initialize, stdinfd]
    )

    assert_send_type  '(int, **untyped) -> IO',
                      IO.allocate, :initialize, stdinfd, THESE_ARE: 'NOT VALID', OPTIONS: true
  end

  def test_initialize_copy
    with_io STDOUT do |io|
      assert_send_type  '(io) -> IO',
                        IO.allocate, :initialize_copy, io
    end
  end

  def test_lsh
    open_write do |io|
      with_to_s do |obj|
        assert_send_type  '(_ToS) -> IO',
                          io, :<<, obj
      end
    end
  end

  def test_advise
    open_either do |io|
      %i[normal sequential random noreuse willneed dontneed].each do |advice|
        assert_send_type  '(IO::advice) -> nil',
                          io, :advise, advice
        with_int.and_nil do |offset|
          assert_send_type  '(IO::advice, int?) -> nil',
                            io, :advise, advice, offset

          with_int.and_nil do |len|
            assert_send_type  '(IO::advice, int?, int?) -> nil',
                              io, :advise, advice, offset, len
          end
        end
      end
    end
  end

  def test_autoclose=
    open_either do |io|
      with_boolish do |bool|
        assert_send_type  '[T] (T) -> T',
                          io, :autoclose=, bool
      end
    end
  end

  def test_autoclose?
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, :autoclose?
    end
  end

  def test_binmode
    open_either do |io|
      assert_send_type  '() -> IO',
                        io, :binmode
    end
  end

  def test_binmode?
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, :binmode?
    end
  end

  def test_close
    open_either do |io|
      assert_send_type  '() -> nil',
                        io, :close
    end
  end

  def test_close_on_exec=
    open_either do |io|
      with_boolish do |boolish|
        assert_send_type  '(boolish) -> nil',
                          io, :close_on_exec=, boolish
      end
    end
  end

  def test_close_on_exec?
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, :close_on_exec?
    end
  end

  def test_close_read
    open_read do |io|
      assert_send_type  '() -> nil',
                        io, :close_read
    end
  end

  def test_close_write
    open_write do |io|
      assert_send_type  '() -> nil',
                        io, :close_write
    end
  end

  def test_closed?
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, :closed?
    end
  end


  def assert_limit_delim(method:, return_type:, path: SMALL_TEXT_FILE)
    open_read path: path do |io|
      assert_send_type  "() -> #{return_type}",
                        io, method
      io.rewind

      with_string("a").and_nil do |delim|
        assert_send_type  "(string?) -> #{return_type}",
                          io, method, delim
        io.rewind

        with_int(10).and_nil do |limit|
          assert_send_type  "(string?, int?) -> #{return_type}",
                            io, method, delim, limit
          io.rewind

          with_boolish do |chomp|
            assert_send_type  "(string?, int?, chomp: boolish) -> #{return_type}",
                              io, method, delim, limit, chomp: chomp
            io.rewind
          end
        end

        with_boolish do |chomp|
          assert_send_type  "(string?, chomp: boolish) -> #{return_type}",
                            io, method, delim, chomp: chomp
          io.rewind
        end
      end

      with_int(10).and_nil do |limit|
        assert_send_type  "(int?) -> #{return_type}",
                          io, method, limit
        io.rewind

        with_boolish do |chomp|
          assert_send_type  "(int?, chomp: boolish) -> #{return_type}",
                            io, method, limit, chomp: chomp
          io.rewind
        end
      end

      with_boolish do |chomp|
        assert_send_type  "(chomp: boolish) -> #{return_type}",
                          io, method, chomp: chomp
        io.rewind
      end
    end
  end

  def test_each(method: :each)
    open_read do |io|
      assert_send_type  '() -> Enumerator[String, IO]',
                        io, method
      io.rewind
      assert_send_type  '() { (String) -> void } -> IO',
                        io, method do end
      io.rewind

      with_string("a").and_nil do |delim|
        assert_send_type  '(string?) -> Enumerator[String, IO]',
                          io, method, delim
        io.rewind
        assert_send_type  '(string?) { (String) -> void } -> IO',
                          io, method, delim do end
        io.rewind

        with_int(10).and_nil do |limit|
          assert_send_type  '(string?, int?) -> Enumerator[String, IO]',
                            io, method, delim, limit
          io.rewind
          assert_send_type  '(string?, int?) { (String) -> void } -> IO',
                            io, method, delim, limit do end
          io.rewind

          with_boolish do |chomp|
            assert_send_type  '(string?, int?, chomp: boolish) -> Enumerator[String, IO]',
                              io, method, delim, limit, chomp: chomp
            io.rewind
            assert_send_type  '(string?, int?, chomp: boolish) { (String) -> void } -> IO',
                              io, method, delim, limit, chomp: chomp do end
            io.rewind
          end
        end

        with_boolish do |chomp|
          assert_send_type  '(string?, chomp: boolish) -> Enumerator[String, IO]',
                            io, method, delim, chomp: chomp
          io.rewind
          assert_send_type  '(string?, chomp: boolish) { (String) -> void } -> IO',
                            io, method, delim, chomp: chomp do end
          io.rewind
        end
      end

      with_int(10).and_nil do |limit|
        assert_send_type  '(int?) -> Enumerator[String, IO]',
                          io, method, limit
        io.rewind
        assert_send_type  '(int?) { (String) -> void } -> IO',
                          io, method, limit do end
        io.rewind

        with_boolish do |chomp|
          assert_send_type  '(int?, chomp: boolish) -> Enumerator[String, IO]',
                            io, method, limit, chomp: chomp
          io.rewind
          assert_send_type  '(int?, chomp: boolish) { (String) -> void } -> IO',
                            io, method, limit, chomp: chomp do end
          io.rewind
        end
      end

      with_boolish do |chomp|
        assert_send_type  '(chomp: boolish) -> Enumerator[String, IO]',
                          io, method, chomp: chomp
        io.rewind
        assert_send_type  '(chomp: boolish) { (String) -> void } -> IO',
                          io, method, chomp: chomp do end
        io.rewind
      end
    end
  end

  def test_each_line
    test_each(method: :each_line)
  end

  def test_each_byte
    open_read do |io|
      assert_send_type  '() -> Enumerator[Integer, IO]',
                        io, :each_byte
      io.rewind
      assert_send_type  '() { (Integer) -> void } -> IO',
                        io, :each_byte do end
    end
  end

  def test_each_char
    open_read do |io|
      assert_send_type  '() -> Enumerator[String, IO]',
                        io, :each_char
      io.rewind
      assert_send_type  '() { (String) -> void } -> IO',
                        io, :each_char do end
    end
  end

  def test_each_codepoint
    open_read do |io|
      assert_send_type  '() -> Enumerator[Integer, IO]',
                        io, :each_codepoint
      io.rewind
      assert_send_type  '() { (Integer) -> void } -> IO',
                        io, :each_codepoint do end
    end
  end

  def test_eof(method: :eof)
    open_read do |io|
      assert_send_type  '() -> bool',
                        io, method
    end
  end

  def test_eof?
    test_eof(method: :eof?)
  end

  def test_external_encoding
    open_write external_encoding: nil do |io|
      assert_send_type  '() -> nil',
                        io, :external_encoding
    end

    open_either external_encoding: 'UTF-8' do |io|
      assert_send_type  '() -> Encoding',
                        io, :external_encoding
    end
  end

  def test_fcntl
    # There's no way to test `fcntl` safely and consistently (as the first argument is
    # system-dependent, and Ruby doesn't expose it), so we'll just leave it untested.
  end

  def test_fdatasync
    open_either do |io|
      assert_send_type  '() -> 0',
                        io, :fdatasync
    end
  end

  def test_fileno(method: :fileno)
    open_either do |io|
      assert_send_type  '() -> Integer',
                        io, method
    end
  end

  def test_flush
    open_either do |io|
      assert_send_type  '() -> IO',
                        io, :flush
    end
  end

  def test_fsync
    open_either do |io|
      assert_send_type  '() -> 0',
                        io, :fsync
    end
  end

  def test_getbyte
    open_read path: File::NULL do |io|
      assert_send_type  '() -> nil',
                        io, :getbyte
    end

    open_read do |io|
      assert_send_type  '() -> Integer',
                        io, :getbyte
    end
  end

  def test_getc
    open_read path: File::NULL do |io|
      assert_send_type  '() -> nil',
                        io, :getc
    end

    open_read do |io|
      assert_send_type  '() -> String',
                        io, :getc
    end
  end

  def test_gets
    assert_limit_delim(method: :gets, return_type: 'String')
    assert_limit_delim(method: :gets, return_type: 'nil', path: File::NULL)
  end

  def test_inspect
    open_either do |io|
      assert_send_type  '() -> String',
                        io, :inspect
    end
  end

  def test_internal_encoding
    open_write internal_encoding: nil do |io|
      assert_send_type  '() -> nil',
                        io, :internal_encoding
    end

    open_either internal_encoding: 'UTF-8' do |io|
      assert_send_type  '() -> Encoding',
                        io, :internal_encoding
    end
  end

  def test_ioctl
    # There's no way to test `ioctl` safely and consistently (as the first argument is
    # system-dependent, and Ruby doesn't expose it), so we'll just leave it untested.
  end

  def test_isatty(method: :isatty)
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, method
    end
  end

  def test_lineno
    open_either do |io|
      assert_send_type  '() -> Integer',
                        io, :lineno
    end
  end

  def test_lineno=
    open_either do |io|
      with_int 0 do |lineno|
        assert_send_type  '[T < _ToInt] (T) -> T',
                          io, :lineno=, lineno
      end
    end
  end

  def test_path(method: :path)
    omit_if RUBY_VERSION < '3.2.0'

    assert_send_type  '() -> nil',
                      IO.new(STDIN.fileno), method # FD 0 doesn't have a path, but STDIN does.
    open_read do |io|
      assert_send_type  '() -> String',
                        io, method
    end
  end

  def test_pid
    open_either do |io|
      assert_send_type  '() -> nil',
                        io, :pid
    end

    io = IO.popen [RUBY_EXE, '-e', '1']
    begin
      assert_send_type  '() -> Integer',
                        io, :pid
    ensure
      io.close
    end
  end

  def test_pos
    test_tell(method: :pos)
  end

  def test_pos=
    open_either do |io|
      with_int 0 do |new_position|
        assert_send_type  '(int) -> Integer',
                          io, :pos=, new_position
      end
    end
  end

  def test_pread
    open_read do |io|
      with_int 3 do |length|
        with_int 10 do |offset|
          assert_send_type  '(int, int) -> String',
                            io, :pread, length, offset

          with_string(+"").and_nil do |out_string|
            assert_send_type  '(int, int, string?) -> String',
                              io, :pread, length, offset, out_string
          end
        end
      end
    end
  end

  def test_print
    open_write do |io|
      assert_send_type  '() -> nil',
                        io, :print

      with_to_s do |object|
        assert_send_type  '(*_ToS) -> nil',
                          io, :print, object, object
      end
    end
  end

  def test_printf
    open_write do |io|
      with_string '%s, %s!' do |fmt|
        assert_send_type  '(string, *untyped) -> nil',
                          io, :printf, fmt, 'hello', 'world'
      end
    end
  end

  def test_putc
    open_write do |io|
      # NOTE: doesn't take a `_ToStr`, but just `String`.
      assert_send_type  '(String) -> String',
                        io, :putc, '&'
      begin
        io.putc ToStr.new('&')
      rescue TypeError
        pass 'io.putc does not accept _ToStr'
      else
        flunk '`io.putc` does not accept _ToStr'
      end

      with_int 38 do |chr|
        assert_send_type  '[T < _ToInt] (T) -> T',
                          io, :putc, chr
      end
    end
  end

  def test_puts
    open_write do |io|
      assert_send_type  '() -> nil',
                        io, :puts

      with_to_s do |object|
        assert_send_type  '(*_ToS) -> nil',
                          io, :puts, object, object
      end
    end
  end

  def test_pwrite
    open_write do |io|
      with_to_s do |object|
        with_int 0 do |offset|
          assert_send_type  '(_ToS, int) -> Integer',
                            io, :pwrite, object, offset
        end
      end
    end
  end

  def test_read
    open_read do |io|
      assert_send_type  '() -> String',
                        io, :read
      io.rewind

      with_int 3 do |length|
        assert_send_type  '(int) -> String',
                          io, :read, length
        io.seek(0, IO::SEEK_END)
        assert_send_type  '(int) -> nil',
                          io, :read, length
        io.rewind

        with_string(+"").and_nil do |outbuf|
          assert_send_type  '(int, string?) -> String',
                            io, :read, length, outbuf
          io.seek(0, IO::SEEK_END)
          assert_send_type  '(int, string?) -> nil',
                            io, :read, length, outbuf
          io.rewind
        end
      end

      io.seek(0, IO::SEEK_END) # reading from end of string with `nil` arg returns `""`.
      assert_send_type  '(nil) -> String',
                        io, :read, nil

      with_string(+"").and_nil do |outbuf|
        assert_send_type  '(nil, string?) -> String',
                          io, :read, nil, outbuf
      end
    end
  end

  def test_read_nonblock
    IO.pipe do |read, write|
      with_int 1 do |len|
        write.write_nonblock('AAA')
        write.flush

        assert_send_type  '(int) -> String',
                          read, :read_nonblock, len
        assert_send_type  '(int, exception: true) -> String',
                          read, :read_nonblock, len, exception: true
        assert_send_type  '(int, exception: false) -> String',
                          read, :read_nonblock, len, exception: false
        assert_send_type  '(int, exception: false) -> :wait_readable', # b/c only 3 chars were written
                          read, :read_nonblock, len, exception: false

        # ensure it actually throws an exception with `exception: true` and doesnt return
        begin
          read.read_nonblock(len)
        rescue IO::WaitReadable
          pass '.read_nonblock without anything left doesnt return nil/:wait_readable'
        else
          flunk '.read_nonblock returned something in the exception: true/not given case?'
        end

        with_string(+"").and_nil do |outbuf|
          write.write_nonblock('AAA')
          write.flush

          assert_send_type  '(int, string?) -> String',
                            read, :read_nonblock, len, outbuf
          assert_send_type  '(int, string?, exception: true) -> String',
                            read, :read_nonblock, len, outbuf, exception: true
          assert_send_type  '(int, string?, exception: false) -> String',
                            read, :read_nonblock, len, outbuf, exception: false
          assert_send_type  '(int, string?, exception: false) -> :wait_readable', # b/c only 3 chars were written
                            read, :read_nonblock, len, outbuf, exception: false

          # ensure it actually throws an exception with `exception: true` and doesnt return
          begin
            read.read_nonblock(len, outbuf)
          rescue IO::WaitReadable
            pass '.read_nonblock without anything left doesnt return nil/:wait_readable'
          else
            flunk '.read_nonblock returned something in the exception: true/not given case?'
          end
        end
      end

      write.close
      with_int 1 do |len|
        assert_send_type  '(int, exception: false) -> nil',
                          read, :read_nonblock, len, exception: false

        # ensure it actually throws an exception with `exception: true` and doesnt return
        begin
          read.read_nonblock(len)
        rescue EOFError
          pass '.read_nonblock without anything left doesnt return nil/:wait_readable'
        else
          flunk '.read_nonblock returned something in the exception: true/not given case?'
        end

        with_string.and_nil do |outbuf|
          assert_send_type  '(int, string?, exception: false) -> nil',
                            read, :read_nonblock, len, outbuf, exception: false

          # ensure it actually throws an exception with `exception: true` and doesnt return
          begin
            read.read_nonblock(len, outbuf)
          rescue EOFError
            pass '.read_nonblock without anything left doesnt return nil/:wait_readable'
          else
            flunk '.read_nonblock returned something in the exception: true/not given case?'
          end
        end
      end
    end
  end

  def test_readbyte
    open_read do |io|
      assert_send_type  '() -> Integer',
                        io, :readbyte
    end
  end

  def test_readchar
    open_read do |io|
      assert_send_type  '() -> String',
                        io, :readchar
    end
  end

  def test_readline
    assert_limit_delim(method: :readline, return_type: 'String')
  end

  def test_readlines
    assert_limit_delim(method: :readlines, return_type: 'Array[String]')
  end

  def test_readpartial
    open_read do |io|
      with_int 3 do |maxlen|
        assert_send_type  '(int) -> String',
                          io, :readpartial, maxlen
        io.rewind

        with_string(+"").and_nil do |outbuf|
          assert_send_type  '(int, string?) -> String',
                            io, :readpartial, maxlen, outbuf
          io.rewind
        end
      end
    end
  end

  def test_reopen
    # We use `open_read` so `with_open_mode` can use the same defaults; reopen doesnt need to just be read.
    open_read do |io|
      with_io STDIN do |newio| # we use STDIN so we can read, so `with_open_mode` can use read.
        assert_send_type  '(io) -> IO',
                          io, :reopen, newio
      end

      with_path File::NULL do |path|
        assert_send_type  '(path) -> IO',
                          io, :reopen, path

        with_open_mode :read do |mode|
          assert_send_type  '(path, IO::open_mode) -> IO',
                            io, :reopen, path, mode
        end
      end

      # rb_io_extract_modeenc:
      with_open_mode do |mode|
        assert_send_type  '(path, mode: IO::open_mode) -> IO',
                          io, :reopen, File::NULL, mode: mode
      end

      with_int(File::Constants::RDONLY).and_nil do |flags|
        assert_send_type  '(path, flags: int?) -> IO',
                          io, :reopen, File::NULL, flags: flags
      end

      # extract_binmode:
      with_boolish do |boolish|
        assert_send_type  '(path, textmode: boolish) -> IO',
                          io, :reopen, File::NULL, textmode: boolish
        assert_send_type  '(path, binmode: boolish) -> IO',
                          io, :reopen, File::NULL, binmode: boolish
      end

      # rb_io_extract_encoding_option:
      with_encoding.and_nil do |enc|
        assert_send_type  '(path, encoding: encoding?) -> IO',
                          io, :reopen, File::NULL, encoding: enc
        assert_send_type  '(path, external_encoding: encoding?, internal_encoding: encoding?) -> IO',
                          io, :reopen, File::NULL, external_encoding: enc, internal_encoding: enc
      end

      verify_encoding_options(
        arg_types: 'path',
        return_type: 'IO',
        args: [io, :reopen, File::NULL]
      )

      assert_send_type  '(path, **untyped) -> IO',
                        io, :reopen, File::NULL, THESE_ARE: 'NOT VALID', OPTIONS: true
    end
  end

  def test_rewind
    open_either do |io|
      assert_send_type  '() -> 0',
                        io, :rewind
    end
  end

  def test_seek
    open_read do |io|
      with_int 3 do |amount|
        assert_send_type  '(int) -> Integer',
                          io, :seek, amount

        whences = %i[SET CUR END]
        whences << :DATA if defined? IO::SEEK_DATA
        whences << :HOLE if defined? IO::SEEK_HOLE

        with_int(3).and(*whences) do |whence|
          assert_send_type  '(int, IO::whence) -> Integer',
                            io, :seek, amount, whence
        end
      end
    end
  end

  def test_set_encoding
    open_either do |io|
      with Encoding::UTF_8, nil do |ext_enc|
        assert_send_type  '(Encoding?, **untyped) -> IO',
                          io, :set_encoding, ext_enc, THESE_ARE: 'NOT VALID', OPTIONS: true
        assert_send_type  '(Encoding?, nil, **untyped) -> IO',
                          io, :set_encoding, ext_enc, nil, THESE_ARE: 'NOT VALID', OPTIONS: true
      end

      # Make sure we use two different encodings; otherwise they'll shortcircuit
      with_encoding Encoding::UTF_8 do |ext_enc|
        with_encoding(Encoding::US_ASCII).and(with_string('-'), nil) do |int_enc|
          assert_send_type  '(encoding, encoding | "-" | nil) -> IO',
                            io, :set_encoding, ext_enc, int_enc

          verify_encoding_options(
            arg_types: 'encoding, encoding | "-" | nil',
            return_type: 'IO',
            args: [io, :set_encoding, ext_enc, int_enc]
          )

          assert_send_type  '(encoding, encoding | "-" | nil, **untyped) -> IO',
                            io, :set_encoding, ext_enc, int_enc, THESE_ARE: 'NOT VALID', OPTIONS: true
        end
      end
    end
  end

  def test_set_encoding_by_bom
    Tempfile.create do |tmp|
      tmp.write "\uFEFFabc"

      open_io tmp, mode: 'r', binmode: true do |io|
        assert_send_type  '() -> Encoding',
                          io, :set_encoding_by_bom
      end
    end

    Tempfile.create do |tmp|
      tmp.write 'abc!'

      open_io tmp, mode: 'r', binmode: true do |io|
        assert_send_type  '() -> nil',
                          io, :set_encoding_by_bom
      end
    end
  end

  def test_stat
    open_either do |io|
      assert_send_type  '() -> File::Stat',
                        io, :stat
    end
  end

  def test_sync
    open_either do |io|
      assert_send_type  '() -> bool',
                        io, :sync
    end
  end

  def test_sync=
    open_either do |io|
      with_boolish do |boolish|
        assert_send_type  '[T] (T) -> T',
                          io, :sync=, boolish
      end
    end
  end

  def test_sysread
    open_read do |io|
      with_int 3 do |maxlen|
        assert_send_type  '(int) -> String',
                          io, :sysread, maxlen
        io.rewind

        with_string(+"").and_nil do |outbuf|
          assert_send_type  '(int, string?) -> String',
                            io, :sysread, maxlen, outbuf
          io.rewind
        end
      end
    end
  end

  def test_sysseek
    open_read do |io|
      with_int 3 do |amount|
        assert_send_type  '(int) -> Integer',
                          io, :sysseek, amount

        whences = %i[SET CUR END]
        whences << :DATA if defined? IO::SEEK_DATA
        whences << :HOLE if defined? IO::SEEK_HOLE

        with_int(3).and(*whences) do |whence|
          assert_send_type  '(int, IO::whence) -> Integer',
                            io, :sysseek, amount, whence
        end
      end
    end
  end

  def test_syswrite
    open_write do |io|
      with_to_s do |object|
        assert_send_type  '(_ToS) -> Integer',
                          io, :syswrite, object
      end
    end
  end

  def test_tell(method: :tell)
    open_either do |io|
      assert_send_type  '() -> Integer',
                        io, method
    end
  end

  def test_timeout
    omit_if RUBY_VERSION < '3.2.0'

    open_either do |io|
      io.timeout = nil
      assert_send_type  '() -> nil',
                        io, :timeout

      io.timeout = 1r
      assert_send_type  '() -> IO::io_timeout',
                        io, :timeout
    end
  end

  def test_timeout=
    omit_if RUBY_VERSION < '3.2.0'

    open_either do |io|
      assert_send_type  '(nil) -> IO',
                        io, :timeout=, nil

      with 1, 1.1, 1r do |timeout|
        assert_send_type  '(IO::io_timeout) -> IO',
                          io, :timeout=, timeout
      end
    end
  end

  def test_to_i
    test_fileno(method: :to_i)
  end

  def test_to_io
    open_either do |io|
      assert_send_type  '() -> IO',
                        io, :to_io
    end
  end

  def test_to_path
    test_path(method: :to_path)
  end

  def test_tty?
    test_isatty(method: :tty?)
  end

  def test_ungetbyte
    open_read do |io|
      with_string('hello world').and 38, nil do |byte|
        assert_send_type  '(Integer | string | nil) -> nil',
                          io, :ungetbyte, byte

      end
    end
  end

  def test_ungetc
    open_read do |io|
      with_string('hello world').and 38 do |chr|
        assert_send_type  '(Integer | string) -> nil',
                          io, :ungetc, chr

      end
    end
  end

  def test_write
    open_write do |io|
      assert_send_type  '() -> Integer',
                        io, :write

      with_to_s do |object|
        assert_send_type  '(*_ToS) -> Integer',
                          io, :write, object, object
      end
    end
  end

  def test_write_nonblock
    IO.pipe do |read, write|
      # don't use `with_to_s` because we want to be certain the object's small enough
      # to be written in one go
      with ToS.new("XYZ") do |object|
        assert_send_type  '(_ToS) -> Integer',
                          write, :write_nonblock, object
        assert_send_type  '(_ToS, exception: true) -> Integer',
                          write, :write_nonblock, object, exception: true
        assert_send_type  '(_ToS, exception: false) -> Integer',
                          write, :write_nonblock, object, exception: false
      end

      with ToS.new("A"*100_000) do |object|
        100.times do
          result = write.write_nonblock(object, exception: false)
          if :wait_writable.equal?(result)
            pass '`.write_nonblock(object, exception: false)` returned `:wait_readable`'
            break
          end
        end and flunk "never got `:wait_readable` even after 100 executions"

        100.times do
          write.write_nonblock(object)
        rescue IO::WaitWritable
          pass '`.write_nonblock(object)` did not return anything when it couldnt write'
          break
        end and flunk "`.write_nonblock(object) returned something when it could write"
      end
    end
  end

  def test_wait
    IO.pipe do |read, write|
      with_int IO::READABLE do |events|
        with_timeout(seconds: 0, nanoseconds: 500).and_nil do |timeout|
          write.puts 'Hello'
          assert_send_type  '(int, Time::_Timeout?) -> Integer',
                            read, :wait, events, timeout
          read.gets

          next if nil.equal?(timeout) # `nil` timeout will never return
          assert_send_type  '(int, Time::_Timeout) -> nil',
                            read, :wait, events, timeout
        end
      end

      # For some reason, `IO.pipe`'s `read` can always be written to, so we need to make sure
      # for the timeout part of the test, we use readable only.
      %i[r read readable].each do |event|
        with_timeout(seconds: 0, nanoseconds: 500) do |timeout|
          assert_send_type  '(*IO::wait_mode | Time::_Timeout) -> nil',
                            read, :wait, event, timeout, event
        end
      end

      %i[r read readable w write writable rw read_write readable_writable].each do |event|
        with_timeout(seconds: 0, nanoseconds: 500) do |timeout|
          write.puts 'hello'
          assert_send_type  '(*IO::wait_mode | Time::_Timeout) -> IO',
                            read, :wait, event, timeout, event
          read.gets
        end
      end

      # NB (@sampersand): I can't figure out how to get `IO#wait` to return `false`, but I can get
      # it to return `true`. Since I can't prove to myself it'll never return `false`, I've left
      # the signature as `bool`, not `true`.
      read.ungetc '&'
      assert_send_type  '(*IO::wait_mode | Time::_Timeout) -> true',
                        read, :wait, :read, 0, :read
    end
  end

  def test_wait_writable
    omit 'todo: test wait_writable'
  end

  def test_wait_priority
    omit 'todo: test wait_priority'
  end
end
