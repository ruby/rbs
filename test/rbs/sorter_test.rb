require "test_helper"
require 'tempfile'
require 'rbs/sorter'

class RBS::SorterTest < Test::Unit::TestCase
  def test_sort
    assert_sort <<~RUBY_EXPECTED, <<~RUBY_ORIG
      class C
        type x = String
        type y = String

        CONST: Integer

        module A
        end

        class B
          def a: () -> void
          def x: () -> void
        end

        interface _I
          def i: () -> void
        end

        include M2
        prepend M1
        extend M3

        @@cvar: String
        self.@civar: String
        @ivar: Integer

        def self?.modfunc: () -> void

        attr_accessor self.a: String
        attr_reader self.b: String
        attr_writer self.c: String

        def self.new: () -> instance
        alias self.bb self.xx
        def self.foo: () -> void
        def self.pub: () -> void

        private

        def self.prv: () -> void

        public

        attr_accessor x: String
        def initialize: () -> void
        def a: () -> void
        def b: () -> void
        alias bb xx
        def c: () -> void
        def pub: () -> void

        private

        def prv: () -> void
      end
    RUBY_EXPECTED
      class C
        alias bb xx

        alias self.bb self.xx

        CONST: Integer

        def c: () -> void

        def b: () -> void

        def a: () -> void

        def initialize: () -> void

        def self?.modfunc: () -> void

        attr_accessor self.a: String

        attr_reader self.b: String

        attr_writer self.c: String

        attr_accessor x: String

        def self.new: () -> instance

        def self.foo: () -> void

        type y = String

        type x = String

        @@cvar: String

        self.@civar: String

        @ivar: Integer

        prepend M1

        include M2

        extend M3

        interface _I
          def i: () -> void
        end

        class B
          def x: () -> void

          def a: () -> void
        end

        module A
        end

        private def prv: () -> void
        public def pub: () -> void
        private def self.prv: () -> void
        public def self.pub: () -> void
      end
    RUBY_ORIG
  end

  def assert_sort(expected, original)
    actual = Tempfile.create('rbs-sort-test-') do |f|
      f.write original
      f.close
      RBS::Sorter.new(Pathname(f.path), stdout: StringIO.new).run

      File.read(f.path)
    end

    actual = actual.lines(chomp: true).reject(&:empty?)
    expected = expected.lines(chomp: true).reject(&:empty?)
    assert_equal expected, actual
  end
end
