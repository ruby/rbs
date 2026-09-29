require_relative "../test_helper"

class IO_Buffer_SingletonTest < Test::Unit::TestCase
  include TestHelper
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

  def test_size_of
    assert_send_type(
      "(Symbol) -> Integer",
      IO::Buffer, :size_of, :u32
    )

    assert_send_type(
      "(Array[Symbol]) -> Integer",
      IO::Buffer, :size_of, [:U8, :f32, :U128]
    )
  end

  def test_string
    with_int 10 do |int|
      assert_send_type(
        "(int) { (IO::Buffer) -> nil } -> String",
        IO::Buffer, :string, int, &proc { nil }
      )
    end
  end
end

class IO_Buffer_InstanceTest < Test::Unit::TestCase
  include TestHelper
  testing "::IO::Buffer"

  BufferSubclass = Class.new(IO::Buffer)

  def test_bitwise_operators
    buffer = IO::Buffer.for("test")
    mask = IO::Buffer.for("\xFF\x00")

    [:&, :|, :^].each do |operator|
      assert_send_type(
        "(IO::Buffer) -> IO::Buffer",
        buffer, operator, mask
      )
    end

    assert_send_type(
      "() -> IO::Buffer",
      buffer, :~
    )
  end

  def test_bitwise_mutation
    mask = IO::Buffer.for("\xFF\x00")

    [:and!, :or!, :xor!].each do |operator|
      assert_send_type(
        "(IO::Buffer) -> IO_Buffer_InstanceTest::BufferSubclass",
        BufferSubclass.new(4), operator, mask
      )
    end

    assert_send_type(
      "() -> IO_Buffer_InstanceTest::BufferSubclass",
      BufferSubclass.new(4), :not!
    )
  end

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

  def test_each
    buf = BufferSubclass.new(2)
    buf.set_string("ab")

    assert_send_type(
      "() -> Enumerator[[Integer, Integer], IO_Buffer_InstanceTest::BufferSubclass]",
      buf, :each
    )
    assert_send_type(
      "(:U8, Integer, Integer) { (Integer, Integer) -> void } -> IO_Buffer_InstanceTest::BufferSubclass",
      buf, :each, :U8, 0, 2
    ) { |_, _| }

    float_buf = BufferSubclass.new(8)
    float_buf.set_values([:F32, :F32], 0, [1.5, 2.5])

    assert_send_type(
      "(:F32) -> Enumerator[[Integer, Float], IO_Buffer_InstanceTest::BufferSubclass]",
      float_buf, :each, :F32
    )
    assert_send_type(
      "(:F32, Integer, Integer) { (Integer, Float) -> void } -> IO_Buffer_InstanceTest::BufferSubclass",
      float_buf, :each, :F32, 0, 2
    ) { |_, _| }
  end

  def test_each_byte
    buf = BufferSubclass.new(3)
    buf.set_string("abc")

    assert_send_type(
      "() -> Enumerator[Integer, IO_Buffer_InstanceTest::BufferSubclass]",
      buf, :each_byte
    )
    assert_send_type(
      "(Integer, Integer) { (Integer) -> void } -> IO_Buffer_InstanceTest::BufferSubclass",
      buf, :each_byte, 1, 2
    ) { |_| }
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

  def test_get_values
    buf = IO::Buffer.new(16)
    buf.set_values([:U8, :F32, :U16], 0, [1, 2.5, 3])

    assert_send_type(
      "(Array[Symbol], Integer) -> Array[Integer | Float]",
      buf, :get_values, [:U8, :F32, :U16], 0
    )

    buf.set_value(:U128, 0, 3)
    assert_send_type(
      "(Array[Symbol], Integer) -> Array[Integer]",
      buf, :get_values, [:U128], 0
    )

    buf.set_values([:F32, :F64], 0, [1.5, 2.5])
    assert_send_type(
      "(Array[Symbol], Integer) -> Array[Float]",
      buf, :get_values, [:F32, :F64], 0
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

  def test_set_values
    buf = IO::Buffer.new(16)

    assert_send_type(
      "(Array[Symbol], Integer, Array[Integer | Float]) -> Integer",
      buf, :set_values, [:U8, :F32, :U16], 0, [1, 2.5, 3]
    )

    assert_send_type(
      "(Array[Symbol], Integer, Array[Integer]) -> Integer",
      buf, :set_values, [:U128], 0, [3]
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

  def test_values
    buf = IO::Buffer.for("abcd")

    assert_send_type(
      "() -> Array[Integer]",
      buf, :values
    )
    assert_send_type(
      "(:U8, Integer, Integer) -> Array[Integer]",
      buf, :values, :U8, 1, 2
    )

    float_buf = IO::Buffer.new(8)
    float_buf.set_values([:F32, :F32], 0, [1.5, 2.5])
    assert_send_type(
      "(:F32, Integer, Integer) -> Array[Float]",
      float_buf, :values, :F32, 0, 2
    )
  end
end
