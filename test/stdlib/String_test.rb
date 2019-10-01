class StringTest < StdlibTest
  target String
  using hook.refinement

  def test_gsub
    s = "string"
    s.gsub(/./, "")
    s.gsub("a", "b")
    s.gsub(/./) {|x| "" }
    s.gsub(/./, {"foo" => "bar"})
    s.gsub(/./)
    s.gsub("")
  end

  def test_bytesize
    s = "string"
    s.bytesize
  end

  def test_endwith
    s = "string"
    s.end_with?
    s.end_with?("foo")
  end

  def test_force_encoding
    s = ""
    s.force_encoding "ASCII-8BIT"
    s.force_encoding Encoding::ASCII_8BIT
  end

  def test_include
    "".include?("")
  end

  def test_initialize
    String.new
    String.new("")
    String.new("", encoding: Encoding::ASCII_8BIT)
    String.new("", encoding: Encoding::ASCII_8BIT, capacity: 123)
    String.new(encoding: Encoding::ASCII_8BIT, capacity: 123)
  end
end
