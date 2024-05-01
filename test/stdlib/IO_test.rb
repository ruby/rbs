require_relative "test_helper"
require 'tempfile'

require "io/wait"

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

  testing "::IO"

  def test_append_symbol
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, "some_file"), "w") do |io|
        assert_send_type "(String) -> File",
                         io, :<<, "foo"
        assert_send_type "(Object) -> File",
                         io, :<<, Object.new
      end
    end
  end

  def test_advise
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :normal
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :sequential
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :random
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :willneed
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :dontneed
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :noreuse
      assert_send_type "(Symbol, Integer) -> nil",
                       io, :advise, :normal, 1
      assert_send_type "(Symbol, Integer, Integer) -> nil",
                       io, :advise, :normal, 1, 2
    end
  end

  def test_autoclose=
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type "(bool) -> bool",
                       io, :autoclose=, true
      assert_send_type "(bool) -> bool",
                       io, :autoclose=, false
      assert_send_type "(::Integer) -> ::Integer",
                       io, :autoclose=, 42
      assert_send_type "(nil) -> nil",
                       io, :autoclose=, nil
    end
  end

  def test_autoclose?
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type "() -> bool",
                       io, :autoclose?
    end
  end

  def test_path
    IO.open(IO.sysopen(File.expand_path(__FILE__)), path: "foo") do |io|
      assert_send_type(
        "() -> String",
        io, :path
      )
    end

    IO.open(IO.sysopen(File.expand_path(__FILE__)), path: nil) do |io|
      assert_send_type(
        "() -> nil",
        io, :path
      )
    end
  end

  def test_read
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type "() -> String",
                       io, :read
      assert_send_type "(Integer) -> String",
                       io, :read, 0
      assert_send_type "(Integer) -> nil",
                       io, :read, 1
      assert_send_type "(nil) -> String",
                       io, :read, nil
      assert_send_type "(Integer, String) -> String",
                       io, :read, 0, +"buffer"
      assert_send_type "(Integer, String) -> nil",
                       io, :read, 1, +"buffer"
      assert_send_type "(nil, String) -> String",
                       io, :read, nil, +"buffer"
    end
  end

  def test_readpartial
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type "(Integer) -> String",
                       io, :readpartial, 10
      assert_send_type "(Integer, String) -> String",
                       io, :readpartial, 10, +"buffer"
    end
  end

  def test_timeout
    io, _ = IO.pipe()

    assert_send_type(
      "(Integer) -> IO",
      io, :timeout=, 1
    )
    assert_send_type(
      "() -> Integer",
      io, :timeout
    )

    assert_send_type(
      "(Float) -> IO",
      io, :timeout=, 1.2
    )
    assert_send_type(
      "() -> Float",
      io, :timeout
    )

    assert_send_type(
      "(Rational) -> IO",
      io, :timeout=, 3r
    )
    assert_send_type(
      "() -> Rational",
      io, :timeout
    )

    assert_send_type(
      "(nil) -> IO",
      io, :timeout=, nil
    )
    assert_send_type(
      "() -> nil",
      io, :timeout
    )
  end

  def test_write
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, "some_file"), "w") do |io|
        assert_send_type "() -> Integer",
                         io, :write
        assert_send_type "(String) -> Integer",
                         io, :write, "foo"
        assert_send_type "(String, Float) -> Integer",
                         io, :write, "foo", 1.5
      end
    end
  end

  def test_close_on_exec
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type '() -> bool',
                       io, :close_on_exec?
      assert_send_type '(::Integer) -> untyped',
                       io, :close_on_exec=, 42
      assert_send_type '() -> bool',
                       io, :close_on_exec?
      assert_send_type '(nil) -> nil',
                       io, :close_on_exec=, nil
      assert_send_type '() -> bool',
                       io, :close_on_exec?
    end
  end

  def test_sync
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type '() -> bool',
                       io, :sync
      assert_send_type '(::Integer) -> ::Integer',
                       io, :sync=, 42
      assert_send_type '() -> bool',
                       io, :sync
      assert_send_type '(nil) -> nil',
                       io, :sync=, nil
      assert_send_type '() -> bool',
                       io, :sync
    end
  end

  def test_gets
    IO.open(IO.sysopen(File.expand_path(__FILE__))) do |io|
      assert_send_type '() -> String',
                       io, :gets
      assert_send_type '(String) -> String',
                       io, :gets, ""
      assert_send_type '(Integer) -> String',
                       io, :gets, 10
      assert_send_type '(chomp: bool) -> String',
                       io, :gets, chomp: true

      assert_send_type '(Integer, chomp: bool) -> String',
                       io, :gets, 42, chomp: true
      assert_send_type '(String, Integer, chomp: bool) -> String',
                       io, :gets, "", 42, chomp: true
      assert_send_type '(String, chomp: bool) -> String',
                       io, :gets, "", chomp: true

      assert_send_type '(nil) -> String',
                       io, :gets, nil
      assert_send_type '(nil, chomp: bool) -> nil',
                       io, :gets, nil, chomp: true
    end
  end
end

class IOWaitTest < Test::Unit::TestCase
  include TestHelper

  testing "::IO"

  def test_readyp
    if_ruby31 do
      # This method returns true|false in Ruby 2.7, nil|IO in 3.0, and true|false in 3.1.

      IO.pipe.tap do |r, w|
        assert_send_type(
          "() -> untyped",
          r, :ready?
        )
      end

      IO.pipe.tap do |r, w|
        w.write("hello")

        assert_send_type(
          "() -> untyped",
          r, :ready?
        )
      end
    end
  end

  def test_wait_readable
    if_ruby "3.0.0"..."3.2.0" do
      IO.pipe.tap do |r, w|
        w.write("hello")

        assert_send_type(
          "() -> IO",
          r, :wait_readable
        )
      end

      IO.pipe.tap do |r, w|
        assert_send_type(
          "(Integer) -> nil",
          r, :wait_readable, 1
        )
      end
    end
  end

  def test_wait_writable
    if_ruby "3.0.0"..."3.2.0" do
      IO.pipe.tap do |r, w|
        assert_send_type(
          "() -> IO",
          w, :wait_writable
        )
      end

      IO.pipe.tap do |r, w|
        assert_send_type(
          "(Integer) -> IO",
          w, :wait_writable, 1
        )
      end
    end
  end

  def test_nread
    IO.pipe.tap do |r, w|
      assert_send_type(
        "() -> Integer",
        r, :nread
      )
    end
  end

  def test_wait
    if_ruby "3.0.0"..."3.2.0" do
      IO.pipe.tap do |r, w|
        w.write("hello")

        assert_send_type(
          "(Integer) -> IO",
          r, :wait, IO::READABLE
        )
      end

      IO.pipe.tap do |r, w|
        w.write("hello")

        assert_send_type(
          "(Integer, Float) -> IO",
          w, :wait, IO::WRITABLE, 0.1
        )
      end
    end

    IO.pipe.tap do |r, w|
      w.write("hello")

      assert_send_type(
        "(Float, :read, :w, :readable_writable) -> IO",
        r, :wait, 0.1, :read, :w, :readable_writable
      )
    end
  end

  def test_set_encoding_by_bom
    open(IO::NULL, 'rb') do |f|
      assert_send_type(
        "() -> nil",
        f, :set_encoding_by_bom
      )
    end

    file = Tempfile.new('test_set_encoding_by_bom')
    file.write("\u{FEFF}abc")
    file.close
    open(file.path, 'rb') do |f|
      assert_send_type(
        "() -> Encoding",
        f, :set_encoding_by_bom
      )
    end
  end
end
