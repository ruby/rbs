# frozen_string_literal: true

require "test/unit"
require "rbs"

module RBS
  module WASM
    # Exercises the WebAssembly-backed parser that RBS uses on JRuby. It runs only
    # on JRuby (where RBS::Parser is implemented by lib/rbs/wasm), and deliberately
    # avoids test_helper so it needs nothing beyond `rbs` itself.
    #
    # Byte-for-byte equivalence with the C extension is covered on CRuby by
    # test/rbs/wasm/serialization_test.rb; here we confirm the same code path works
    # end to end through WebAssembly on JRuby.
    #
    # Nested modules (rather than `class RBS::WASM::JRubyParserTest`) so the file
    # also loads on CRuby, where RBS::WASM is otherwise absent and the test omits.
    class JRubyParserTest < Test::Unit::TestCase
      ROOT = File.expand_path("../../..", __dir__)

      def setup
        omit "Only runs on the JRuby/WebAssembly parser" unless RUBY_ENGINE == "jruby"
      end

      def test_parses_every_bundled_signature
        paths = Dir.glob(File.join(ROOT, "{core,stdlib,sig}/**/*.rbs")).sort
        assert_operator paths.size, :>, 0, "expected to find bundled RBS files"

        paths.each do |path|
          source = File.read(path, encoding: "UTF-8")
          _buffer, _directives, declarations = RBS::Parser.parse_signature(source)
          assert_not_nil declarations, "failed to parse #{path}"
        end
      end

      def test_parse_signature_structure
        _buffer, _directives, declarations = RBS::Parser.parse_signature(<<~RBS)
          class Foo < Bar
            attr_reader name: String
            def greet: (String name) -> String
          end
        RBS

        decl = declarations[0]
        assert_instance_of RBS::AST::Declarations::Class, decl
        assert_equal "Foo", decl.name.to_s
        assert_equal "Bar", decl.super_class&.name&.to_s
        assert_equal [:name, :greet], decl.members.map { |member| member.respond_to?(:name) ? member.name : nil }
        assert_equal 1, decl.location.start_line
      end

      def test_parse_type
        assert_equal "Hash[Symbol, Array[Integer]]", RBS::Parser.parse_type("Hash[Symbol, Array[Integer]]").to_s
        assert_equal "^(Integer, ?String) { () -> void } -> bool", RBS::Parser.parse_type("^(Integer, ?String) { () -> void } -> bool").to_s
        assert_equal "A | B", RBS::Parser.parse_type("A | B", variables: [:A, :B]).to_s
      end

      def test_parse_method_type
        assert_equal "[T] (T, ?Integer) { (T) -> void } -> T", RBS::Parser.parse_method_type("[T] (T, ?Integer) { (T) -> void } -> T").to_s
      end

      def test_parse_error_raises_parsing_error
        error = assert_raises(RBS::ParsingError) do
          RBS::Parser.parse_signature("class 123 Broken end")
        end
        assert_not_nil error.location
        assert_equal "tINTEGER", error.token_type
      end
    end
  end
end
