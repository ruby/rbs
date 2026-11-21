require_relative "test_helper"

require "psych"
require "date"
require "tmpdir"

class PsychSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych", "date"
  testing "singleton(::Psych)"

  def test_LIBYAML_VERSION
    assert_const_type "String", "Psych::LIBYAML_VERSION"
  end

  def test_VERSION
    assert_const_type "String", "Psych::VERSION"
  end

  def test_libyaml_version
    assert_send_type(
      "() -> [::Integer, ::Integer, ::Integer]",
      Psych, :libyaml_version
    )
  end

  def test_load
    assert_send_type(
      "(::String) -> untyped",
      Psych, :load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, filename: ::_ToS, fallback: ::Integer, symbolize_names: bool, freeze: bool) -> untyped",
      Psych, :load, <<-YAML, filename: ToS.new("foo.yaml"), fallback: 123, symbolize_names: true, freeze: true
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, strict_integer: bool) -> untyped",
      Psych, :load, <<-YAML, permitted_classes: [Date], permitted_symbols: [:foo], aliases: true, strict_integer: true
foo: &foo 2026-11-05
bar: *foo
      YAML
    )
  end

  def test_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        Psych, :load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, fallback: ::String, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :load_file, Pathname(File.join(dir, "test.yaml")), fallback: "foo", symbolize_names: false, freeze: false
      )

      assert_send_type(
        "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, strict_integer: bool) -> untyped",
        Psych, :load_file, File.join(dir, "test.yaml"), permitted_classes: [Date], permitted_symbols: [:foo], aliases: true, strict_integer: true
      )
    end
  end

  def test_safe_load
    assert_send_type(
      "(::String) -> untyped",
      Psych, :safe_load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, filename: ::_ToS, fallback: ::Symbol, symbolize_names: bool, freeze: bool) -> untyped",
      Psych, :safe_load, <<-YAML, permitted_classes: [Integer], permitted_symbols: [:foo], aliases: true, filename: ToS.new("foo.yaml"), fallback: :foo, symbolize_names: true, freeze: false
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, strict_integer: bool) -> untyped",
      Psych, :safe_load, <<-YAML, strict_integer: true
foo: 123
      YAML
    )
  end

  def test_safe_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        Psych, :safe_load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, fallback: ::Symbol, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :safe_load_file, Pathname(File.join(dir, "test.yaml")), permitted_classes: [Integer], permitted_symbols: [:foo], aliases: true, fallback: :foo, symbolize_names: true, freeze: false
      )

      assert_send_type(
        "(::String, strict_integer: bool) -> untyped",
        Psych, :safe_load_file, File.join(dir, "test.yaml"), strict_integer: true
      )
    end
  end

  def test_unsafe_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        Psych, :unsafe_load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, fallback: ::String, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :unsafe_load_file, Pathname(File.join(dir, "test.yaml")), fallback: "foo", symbolize_names: false, freeze: false
      )

      assert_send_type(
        "(::String, strict_integer: bool) -> untyped",
        Psych, :unsafe_load_file, File.join(dir, "test.yaml"), strict_integer: true
      )
    end
  end

  def test_dump
    assert_send_type(
      "(::Array[::Integer]) -> ::String",
      Psych, :dump, [1]
    )

    assert_send_type(
      "(::Array[::Integer], ::StringIO) -> ::StringIO",
      Psych, :dump, [1], StringIO.new()
    )

    assert_send_type(
      "(::Array[::Integer], indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool) -> ::String",
      Psych, :dump, [1], indentation: 3, line_width: 30, canonical: true, header: true
    )

    assert_send_type(
      "(::Hash[::Symbol, ::Integer], ::StringIO, stringify_names: bool) -> ::StringIO",
      Psych, :dump, { foo: 1 }, StringIO.new(), stringify_names: true
    )
  end

  def test_safe_dump
    assert_send_type(
      "(::Array[::Integer]) -> ::String",
      Psych, :safe_dump, [1]
    )

    assert_send_type(
      "(::Array[::Integer], ::StringIO) -> ::StringIO",
      Psych, :safe_dump, [1], StringIO.new()
    )

    assert_send_type(
      "(::Array[::Date], ::StringIO, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool) -> ::StringIO",
      Psych, :safe_dump, [Date.new(2026, 11, 5)], StringIO.new(), permitted_classes: [Date], permitted_symbols: [:foo], aliases: true
    )

    assert_send_type(
      "(::Hash[::String, ::Integer], ::StringIO, indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool, stringify_names: bool) -> ::StringIO",
      Psych, :safe_dump, { "foo" => 1 }, StringIO.new(), indentation: 3, line_width: 30, canonical: true, header: true, stringify_names: true
    )
  end

  def test_load_stream
    assert_send_type(
      "(::String) -> ::Array[::Integer | ::String]",
      Psych, :load_stream, "--- 1\n--- foo\n"
    )

    assert_send_type(
      "(::String, filename: ::String, symbolize_names: bool, freeze: bool, strict_integer: bool) -> ::Array[::Hash[::Symbol, ::Integer]]",
      Psych, :load_stream, "--- {foo: 1}\n", filename: "foo.yaml", symbolize_names: true, freeze: true, strict_integer: true
    )

    assert_send_type(
      "(::String, fallback: nil) -> nil",
      Psych, :load_stream, "", fallback: nil
    )

    assert_send_type(
      "(::String, fallback: nil) -> ::Array[::Integer]",
      Psych, :load_stream, "--- 1\n", fallback: nil
    )

    assert_send_type(
      "(::String) { (::Integer) -> void } -> void",
      Psych, :load_stream, "--- 1\n--- 2\n"
    ) { |document| document }
  end

  def test_dump_stream
    assert_send_type(
      "(::Integer) -> ::String",
      Psych, :dump_stream, 1
    )

    assert_send_type(
      "(::Integer, ::String, ::Hash[::String, ::Integer]) -> ::String",
      Psych, :dump_stream, 1, "foo", { "bar" => 2 }
    )
  end

  def test_to_json
    assert_send_type(
      "(::Hash[::String, ::Array[::Integer]]) -> ::String",
      Psych, :to_json, { "foo" => [1] }
    )
  end

  def test_to_yaml
    assert_send_type(
      "() -> ::String",
      [1], :to_yaml
    )

    assert_send_type(
      "(::StringIO) -> ::StringIO",
      [1], :to_yaml, StringIO.new()
    )

    assert_send_type(
      "(indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool) -> ::String",
      [1], :to_yaml, indentation: 3, line_width: 30, canonical: true, header: true
    )
  end

  def test_parse
    assert_send_type(
      "(::String) -> ::Psych::Nodes::Document",
      Psych, :parse, "--- a"
    )
    assert_send_type(
      "(::String) -> false",
      Psych, :parse, ""
    )
    assert_send_type(
      "(::String, filename: ::String) -> ::Psych::Nodes::Document",
      Psych, :parse, "--- a", filename: "a.yml"
    )
  end

  def test_parse_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "a.yml")
      File.write(path, "--- a")
      empty = File.join(dir, "empty.yml")
      File.write(empty, "")

      assert_send_type(
        "(::String) -> ::Psych::Nodes::Document",
        Psych, :parse_file, path
      )
      assert_send_type(
        "(::Pathname) -> ::Psych::Nodes::Document",
        Psych, :parse_file, Pathname(path)
      )
      assert_send_type(
        "(::String) -> false",
        Psych, :parse_file, empty
      )
      assert_send_type(
        "(::String, fallback: ::Symbol) -> ::Symbol",
        Psych, :parse_file, empty, fallback: :none
      )
    end
  end

  def test_parse_stream
    assert_send_type(
      "(::String) -> ::Psych::Nodes::Stream",
      Psych, :parse_stream, "--- a\n--- b"
    )
    assert_send_type(
      "(::String, filename: ::String) -> ::Psych::Nodes::Stream",
      Psych, :parse_stream, "--- a\n--- b", filename: "a.yml"
    )
    assert_send_type(
      "(::String) { (::Psych::Nodes::Document) -> void } -> void",
      Psych, :parse_stream, "--- a\n--- b"
    ) { |doc| doc }
  end
end

class PsychObjectSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Object)"

  class Tagged
  end

  def test_yaml_tag
    assert_send_type(
      "(::String) -> ::String",
      Tagged, :yaml_tag, "!rbs-test/tagged"
    )
  end
end

module PsychNodesTestHelper
  YAML_SOURCE = <<~YAML
    %YAML 1.1
    %TAG !e! tag:example.com,2000:
    --- !e!list
    a: &x [1, "q"]
    b: *x
  YAML

  def stream
    Psych.parse_stream(YAML_SOURCE)
  end

  def document
    stream.children[0]
  end

  def mapping
    document.root
  end

  def sequence
    mapping.children[1]
  end

  def scalar
    mapping.children[0]
  end

  def alias_node
    mapping.children[3]
  end
end

class PsychNodesNodeTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Node"

  def test_children
    assert_send_type "() -> ::Array[::Psych::Nodes::Node]",
                     stream, :children
  end

  def test_tag
    assert_send_type "() -> nil",
                     stream, :tag
    assert_send_type "() -> ::String",
                     mapping, :tag
  end

  def test_location
    node = stream
    %i[start_line start_column end_line end_column].each do |name|
      assert_send_type "() -> ::Integer",
                       node, name
      assert_send_type "(::Integer) -> ::Integer",
                       node, :"#{name}=", 1
    end

    built = Psych::Nodes::Scalar.new("a")
    %i[start_line start_column end_line end_column].each do |name|
      assert_send_type "() -> nil",
                       built, name
    end
  end

  def test_each
    assert_send_type "() { (::Psych::Nodes::Node) -> void } -> void",
                     stream, :each do |node| node end
    assert_send_type "() -> ::Enumerator[::Psych::Nodes::Node, void]",
                     stream, :each
  end

  def test_to_ruby
    assert_send_type "() -> untyped",
                     stream, :to_ruby
    assert_send_type "(symbolize_names: bool, freeze: bool, strict_integer: bool) -> untyped",
                     document, :to_ruby, symbolize_names: true, freeze: true, strict_integer: true
    assert_send_type "() -> untyped",
                     document, :transform
  end

  def test_yaml
    assert_send_type "() -> ::String",
                     stream, :yaml
    assert_send_type "(nil, ::Hash[::Symbol, ::Integer]) -> ::String",
                     stream, :yaml, nil, { line_width: 20 }
    assert_send_type "(::StringIO) -> ::StringIO",
                     stream, :yaml, StringIO.new
    assert_send_type "(::StringIO, ::Hash[::Symbol, ::Integer]) -> ::StringIO",
                     stream, :to_yaml, StringIO.new, { indentation: 4 }
  end

  def test_predicates
    %i[alias? document? mapping? scalar? sequence? stream?].each do |name|
      assert_send_type "() -> bool",
                       scalar, name
    end
  end
end

class PsychNodesAliasTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Alias"

  def test_anchor
    assert_send_type "() -> ::String",
                     alias_node, :anchor
    assert_send_type "(::String) -> ::String",
                     alias_node, :anchor=, "y"
  end

  def test_alias?
    assert_send_type "() -> true",
                     alias_node, :alias?
  end
end

class PsychNodesDocumentTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Document"

  def test_attributes
    doc = document
    assert_send_type "() -> ::Array[::Integer]",
                     doc, :version
    assert_send_type "(::Array[::Integer]) -> ::Array[::Integer]",
                     doc, :version=, [1, 2]
    assert_send_type "() -> ::Array[[::String, ::String]]",
                     doc, :tag_directives
    assert_send_type "(::Array[[::String, ::String]]) -> ::Array[[::String, ::String]]",
                     doc, :tag_directives=, [["!a!", "tag:a,2000:"]]
    assert_send_type "() -> bool",
                     doc, :implicit
    assert_send_type "(bool) -> bool",
                     doc, :implicit=, true
    assert_send_type "() -> bool",
                     doc, :implicit_end
    assert_send_type "(bool) -> bool",
                     doc, :implicit_end=, false
  end

  def test_root
    assert_send_type "() -> ::Psych::Nodes::Mapping",
                     document, :root
    assert_send_type "() -> nil",
                     Psych::Nodes::Document.new, :root
  end

  def test_document?
    assert_send_type "() -> true",
                     document, :document?
  end
end

class PsychNodesMappingTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Mapping"

  def test_attributes
    node = mapping
    assert_send_type "() -> nil",
                     node, :anchor
    assert_send_type "(::String) -> ::String",
                     node, :anchor=, "m"
    assert_send_type "() -> ::String",
                     node, :tag
    assert_send_type "(nil) -> nil",
                     node, :tag=, nil
    assert_send_type "() -> bool",
                     node, :implicit
    assert_send_type "(bool) -> bool",
                     node, :implicit=, true
    assert_send_type "() -> ::Integer",
                     node, :style
    assert_send_type "(::Integer) -> ::Integer",
                     node, :style=, Psych::Nodes::Mapping::FLOW
  end

  def test_mapping?
    assert_send_type "() -> true",
                     mapping, :mapping?
  end
end

class PsychNodesScalarTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Scalar"

  def test_attributes
    node = scalar
    assert_send_type "() -> ::String",
                     node, :value
    assert_send_type "(::String) -> ::String",
                     node, :value=, "z"
    assert_send_type "() -> nil",
                     node, :anchor
    assert_send_type "(::String) -> ::String",
                     node, :anchor=, "s"
    assert_send_type "() -> nil",
                     node, :tag
    assert_send_type "(::String) -> ::String",
                     node, :tag=, "!str"
    assert_send_type "() -> bool",
                     node, :plain
    assert_send_type "(bool) -> bool",
                     node, :plain=, false
    assert_send_type "() -> bool",
                     node, :quoted
    assert_send_type "(bool) -> bool",
                     node, :quoted=, true
    assert_send_type "() -> ::Integer",
                     node, :style
    assert_send_type "(::Integer) -> ::Integer",
                     node, :style=, Psych::Nodes::Scalar::DOUBLE_QUOTED
  end

  def test_scalar?
    assert_send_type "() -> true",
                     scalar, :scalar?
  end
end

class PsychNodesSequenceTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Sequence"

  def test_attributes
    node = sequence
    assert_send_type "() -> ::String",
                     node, :anchor
    assert_send_type "(nil) -> nil",
                     node, :anchor=, nil
    assert_send_type "() -> nil",
                     node, :tag
    assert_send_type "() -> bool",
                     node, :implicit
    assert_send_type "() -> ::Integer",
                     node, :style
    assert_send_type "(::Integer) -> ::Integer",
                     node, :style=, Psych::Nodes::Sequence::BLOCK
  end

  def test_sequence?
    assert_send_type "() -> true",
                     sequence, :sequence?
  end
end

class PsychNodesStreamTest < Test::Unit::TestCase
  include TestHelper
  include PsychNodesTestHelper

  library "psych"
  testing "::Psych::Nodes::Stream"

  def test_encoding
    assert_send_type "() -> ::Integer",
                     stream, :encoding
    assert_send_type "(::Integer) -> ::Integer",
                     stream, :encoding=, Psych::Nodes::Stream::UTF16LE
  end

  def test_stream?
    assert_send_type "() -> true",
                     stream, :stream?
  end
end

class PsychNodesConstantsTest < Test::Unit::TestCase
  include TestHelper

  library "psych"

  def test_constants
    %w[Mapping::ANY Mapping::BLOCK Mapping::FLOW
       Scalar::ANY Scalar::PLAIN Scalar::SINGLE_QUOTED Scalar::DOUBLE_QUOTED Scalar::LITERAL Scalar::FOLDED
       Sequence::ANY Sequence::BLOCK Sequence::FLOW
       Stream::ANY Stream::UTF8 Stream::UTF16LE Stream::UTF16BE].each do |name|
      assert_const_type "Integer", "Psych::Nodes::#{name}"
    end
  end

end

class PsychNodesAliasSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Alias)"

  def test_new
    assert_send_type "(::String) -> ::Psych::Nodes::Alias",
                     Psych::Nodes::Alias, :new, "x"
  end
end

class PsychNodesDocumentSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Document)"

  def test_new
    assert_send_type "() -> ::Psych::Nodes::Document",
                     Psych::Nodes::Document, :new
    assert_send_type "(::Array[::Integer], ::Array[[::String, ::String]], bool) -> ::Psych::Nodes::Document",
                     Psych::Nodes::Document, :new, [1, 1], [["!a!", "tag:a,2000:"]], true
  end
end

class PsychNodesMappingSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Mapping)"

  def test_new
    assert_send_type "() -> ::Psych::Nodes::Mapping",
                     Psych::Nodes::Mapping, :new
    assert_send_type "(::String, ::String, bool, ::Integer) -> ::Psych::Nodes::Mapping",
                     Psych::Nodes::Mapping, :new, "a", "!t", false, Psych::Nodes::Mapping::FLOW
  end
end

class PsychNodesScalarSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Scalar)"

  def test_new
    assert_send_type "(::String) -> ::Psych::Nodes::Scalar",
                     Psych::Nodes::Scalar, :new, "v"
    assert_send_type "(::String, nil, nil, bool, bool, ::Integer) -> ::Psych::Nodes::Scalar",
                     Psych::Nodes::Scalar, :new, "v", nil, nil, false, true, Psych::Nodes::Scalar::DOUBLE_QUOTED
  end
end

class PsychNodesSequenceSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Sequence)"

  def test_new
    assert_send_type "() -> ::Psych::Nodes::Sequence",
                     Psych::Nodes::Sequence, :new
    assert_send_type "(nil, nil, bool, ::Integer) -> ::Psych::Nodes::Sequence",
                     Psych::Nodes::Sequence, :new, nil, nil, true, Psych::Nodes::Sequence::FLOW
  end
end

class PsychNodesStreamSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Psych::Nodes::Stream)"

  def test_new
    assert_send_type "() -> ::Psych::Nodes::Stream",
                     Psych::Nodes::Stream, :new
    assert_send_type "(::Integer) -> ::Psych::Nodes::Stream",
                     Psych::Nodes::Stream, :new, Psych::Nodes::Stream::UTF8
  end
end
