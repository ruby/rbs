require_relative "../test_helper"

class IO_Buffer_SingletonTest < Test::Unit::TestCase
  include TypeAssertions
  testing "singleton(::IO::Buffer)"

  def test_for
    assert_send_type(
      "(String) -> IO::Buffer",
      IO::Buffer, :for, "Hello world"
    )
  end

  def test_map
    tmpdir = Dir.mktmpdir
    path = File.join(tmpdir, "foo")
    File.write(path, "Hello World")

    assert_send_type(
      "(File, nil, Integer, Integer) -> IO::Buffer",
      IO::Buffer, :map, File.open(path), nil, 0, IO::Buffer::READONLY
    )
  end

  def test_new
    assert_send_type(
      "() -> IO::Buffer",
      IO::Buffer, :new
    )

    assert_send_type(
      "(Integer, Integer) -> IO::Buffer",
      IO::Buffer, :new, 10, IO::Buffer::INTERNAL
    )
  end
end

class IO_Buffer_InstanceTest < Test::Unit::TestCase
  include TypeAssertions
  testing "::IO::Buffer"

  def test_spaceship
    buf1 = IO::Buffer.for("")
    buf2 = IO::Buffer.for("test")

    assert_send_type(
      "(IO::Buffer) -> Integer",
      buf1, :<=>, buf2
    )

    assert_send_type(
      "(IO::Buffer) -> Integer",
      buf1, :<=>, buf1
    )
  end

  def test_clear
    buf = IO::Buffer.new

    assert_send_type(
      "() -> IO::Buffer",
      buf, :clear
    )
    assert_send_type(
      "(Integer, Integer, Integer) -> IO::Buffer",
      buf, :clear, 2, 1, 2
    )
  end

  def test_copy
    buf = IO::Buffer.new
    src = IO::Buffer.for("srcsrcsrc")

    assert_send_type(
      "(IO::Buffer) -> Integer",
      buf, :copy, src
    )
    assert_send_type(
      "(IO::Buffer, Integer, Integer, Integer) -> Integer",
      buf, :copy, src, 1, 2, 3
    )
  end

  def test_empty?
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> bool",
      buf, :empty?
    )
  end

  def test_external?
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> bool",
      buf, :external?
    )
  end

  def test_free
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> IO::Buffer",
      buf, :free
    )
  end

  def test_get_string
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> String",
      buf, :get_string
    )
    assert_send_type(
      "(Integer, Integer, Encoding) -> String",
      buf, :get_string, 1, 2, Encoding::UTF_8
    )
  end

  def test_get_value
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "(Symbol, Integer) -> Integer",
      buf, :get_value, :u16, 1
    )
    assert_send_type(
      "(Symbol, Integer) -> Float",
      buf, :get_value, :F64, 1
    )
  end

  def test_hexdump
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> String",
      buf, :hexdump
    )
  end

  def test_inspect
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() -> String",
      buf, :inspect
    )
  end

  def test_internal?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :internal?
    )
  end

  def test_locked
    buf = IO::Buffer.for("hello world")

    assert_send_type(
      "() { (IO::Buffer) -> String } -> String",
      buf, :locked
    ) do "hello" end
  end

  def test_locked?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :locked?
    )
  end

  def test_mapped?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :mapped?
    )
  end

  def test_null?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :null?
    )
  end

  def test_readonly?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :readonly?
    )
  end

  def test_resize
    buf = IO::Buffer.new

    assert_send_type(
      "(Integer) -> IO::Buffer",
      buf, :resize, 2
    )
  end

  def test_set_value
    buf = IO::Buffer.new(30)

    assert_send_type(
      "(Symbol, Integer, Integer) -> Integer",
      buf, :set_value, :U16, 0, 123
    )
  end

  def test_size
    assert_send_type(
      "() -> Integer",
      IO::Buffer.for(""), :size
    )
  end

  def test_slice
    buf = IO::Buffer.new(30)

    assert_send_type(
      "(Integer, Integer) -> IO::Buffer",
      buf, :slice, 0, 5
    )
  end

  def test_to_s
    assert_send_type(
      "() -> String",
      IO::Buffer.for(""), :to_s
    )
  end

  def test_transfer
    assert_send_type(
      "() -> IO::Buffer",
      IO::Buffer.for(""), :transfer
    )
  end

  def test_valid?
    assert_send_type(
      "() -> bool",
      IO::Buffer.for(""), :valid?
    )
  end
end
