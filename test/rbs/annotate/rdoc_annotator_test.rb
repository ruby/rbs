require "test_helper"

return if ENV["RUBY"]

class RBS::Annotate::RDocAnnotatorTest < Test::Unit::TestCase
  def load_source(files)
    Dir.mktmpdir do |dir|
      path = Pathname(dir)

      (path + "lib").mkdir

      files.each do |file, content|
        (path + "lib" + file).write(content)
      end

      system(
        "rdoc -q --ri -o #{path}/doc --root=#{path} #{path}/lib",
      )

      source = RBS::Annotate::RDocSource.new()
      source.with_system_dir = false
      source.extra_dirs << (path + "doc")

      source.load()

      source
    end
  end

  def parse_rbs(src)
    _, _, decls = RBS::Parser.parse_signature(src)
    decls
  end

  def tester(*false_paths)
    Object.new.tap do |obj|
      obj.singleton_class.define_method(:test_path) {|path| !false_paths.include?(path) }
    end
  end

  def test_annotate_class
    source = load_source(
      {
        "cli.rb" => <<-RUBY,
# This is a doc for CLI.
class CLI
end
        RUBY
        "helper.rb" => <<-RUBY
# This is another doc for CLI.
class CLI
  # This is a doc for CLI::Helper
  class Helper
  end
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
class CLI
  class Helper
  end
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)

    decls[0].tap do |decl|
      annotator.annotate_class(decl, outer: [])

      assert_equal <<-TEXT, decl.comment.string
<!-- rdoc-file=lib/cli.rb -->
This is a doc for CLI.

<!-- rdoc-file=lib/helper.rb -->
This is another doc for CLI.

      TEXT

      decl.members[0].tap do |decl|
        annotator.annotate_class(decl, outer: [TypeName("CLI").to_namespace])

        assert_equal <<-TEXT, decl.comment.string
<!-- rdoc-file=lib/helper.rb -->
This is a doc for CLI::Helper

        TEXT
      end
    end
  end

  def test_docs_for_method_method
    source = load_source(
      {
        "cli.rb" => <<-RUBY,
class Foo
  # Doc for m1
  def m1; end

  # Doc for m2
  alias m2 m1

  # Doc for m3
  attr_accessor :m3

  # Doc for m4
  attr_reader :m4
end
        RUBY
      }
    )

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)

    assert_equal <<-TEXT, annotator.doc_for_method(TypeName("Foo"), instance_method: :m1, tester: tester)
<!--
  rdoc-file=lib/cli.rb
  - m1()
-->
Doc for m1

    TEXT

    assert_equal <<-TEXT, annotator.doc_for_method(TypeName("Foo"), instance_method: :m2, tester: tester)
<!-- rdoc-file=lib/cli.rb -->
Doc for m2

    TEXT

    assert_equal <<-TEXT, annotator.doc_for_method(TypeName("Foo"), instance_method: :m3, tester: tester)
<!-- rdoc-file=lib/cli.rb -->
Doc for m3

    TEXT

    assert_equal <<-TEXT, annotator.doc_for_method(TypeName("Foo"), instance_method: :m3=, tester: tester)
<!-- rdoc-file=lib/cli.rb -->
Doc for m3

    TEXT

    assert_nil annotator.doc_for_method(TypeName("Foo"), instance_method: :m4=, tester: tester)
  end

  def assert_annotated_decls(expected, decls)
    strio = StringIO.new
    writer = RBS::Writer.new(out: strio)
    writer.write(decls)

    assert_equal expected, strio.string
  end

  def test_annotate1_defs
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
# Doc for Foo
class Foo
  # Doc for m1
  def m1; end

  # Doc for m2
  alias m2 m1

  # Doc for m3
  attr_reader :m3

  # Doc for m4
  attr_writer :m4

  # Doc for m5
  attr_accessor :m5
end

class Bar
  class <<self
    # Doc for Bar.m1
    def m1; end

    # Doc for Bar.m2
    alias m2 m1

    # Doc for Bar.m3
    attr_reader :m3

    # Doc for Bar.m4
    attr_writer :m4

    # Doc for Bar.m5
    attr_accessor :m5
  end
end
        RUBY
      }
    )

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)

    decls = parse_rbs(<<-RBS)
class Foo
  def m1: () -> void

  def m2: () -> void

  def m3: () -> void

  def m3=: () -> void

  def m4: () -> void

  def m4=: () -> void

  def m5: () -> void

  def m5: () -> void
end

class Bar
  def self.m1: () -> void

  def self.m2: () -> void

  def self.m3: () -> void

  def self.m3=: () -> void

  def self.m4: () -> void

  def self.m4=: () -> void

  def self.m5: () -> void

  def self.m5: () -> void
end
RBS

    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
# <!-- rdoc-file=lib/foo.rb -->
# Doc for Foo
#
class Foo
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m1()
  # -->
  # Doc for m1
  #
  def m1: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m2
  #
  def m2: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m3
  #
  def m3: () -> void

  def m3=: () -> void

  def m4: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m4
  #
  def m4=: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m5
  #
  def m5: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m5
  #
  def m5: () -> void
end

class Bar
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m1()
  # -->
  # Doc for Bar.m1
  #
  def self.m1: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for Bar.m2
  #
  def self.m2: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for Bar.m3
  #
  def self.m3: () -> void

  def self.m3=: () -> void

  def self.m4: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for Bar.m4
  #
  def self.m4=: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for Bar.m5
  #
  def self.m5: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for Bar.m5
  #
  def self.m5: () -> void
end
    RBS
  end

  def test_annotate2_aliases
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
class Foo
  # Doc for m1
  def m1; end

  # Doc for m2 (alias)
  alias m2 m1

  # Doc for m3 (def)
  def m3; end

  # Doc for m4 (attr_reader)
  attr_reader :m4
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
class Foo
  def m1: () -> void

  alias m2 m1

  alias m3 m1

  alias m4 m1
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
class Foo
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m1()
  # -->
  # Doc for m1
  #
  def m1: () -> void

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m2 (alias)
  #
  alias m2 m1

  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m3()
  # -->
  # Doc for m3 (def)
  #
  alias m3 m1

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m4 (attr_reader)
  #
  alias m4 m1
end
    RBS
  end


  def test_annotate3_attrs
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
class Foo
  # Doc for m1 (attr_accessor)
  attr_accessor :m1

  # Doc for m2 (def)
  def m2; end

  # Doc for m2= (def)
  def m2=; end

  # Doc for m3 (alias)
  alias m3 m2

  # Doc for m3= (alias)
  alias m3= m2=
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
class Foo
  attr_accessor m1: untyped

  attr_accessor m2: untyped

  attr_accessor m3: untyped
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
class Foo
  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m1 (attr_accessor)
  #
  attr_accessor m1: untyped

  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m2()
  # -->
  # Doc for m2 (def)
  # ----
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - m2=()
  # -->
  # Doc for m2= (def)
  #
  attr_accessor m2: untyped

  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m3 (alias)
  # ----
  # <!-- rdoc-file=lib/foo.rb -->
  # Doc for m3= (alias)
  #
  attr_accessor m3: untyped
end
    RBS
  end

  def test_annotate_skip_annotation
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
# This is doc for Foo
class Foo
  # This is doc for Foo#foo
  def foo; end
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
%a{annotate:rdoc:skip}
class Foo
  def foo: () -> void
end

%a{annotate:rdoc:skip:all}
class Foo
  def foo: () -> void
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
%a{annotate:rdoc:skip}
class Foo
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - foo()
  # -->
  # This is doc for Foo#foo
  #
  def foo: () -> void
end

%a{annotate:rdoc:skip:all}
class Foo
  def foo: () -> void
end
        RBS
  end

  def test_annotate_source_annotation
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
# Doc Foo from foo.rb
class Foo
end
        RUBY
        "bar.rb" => <<-RUBY
# Doc of Foo from bar.rb
class Foo
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
class Foo
end

%a{annotate:rdoc:source:from=lib/foo.rb}
class Foo
end

%a{annotate:rdoc:source:skip=lib/foo.rb}
class Foo
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
# <!-- rdoc-file=lib/bar.rb -->
# Doc of Foo from bar.rb
#
# <!-- rdoc-file=lib/foo.rb -->
# Doc Foo from foo.rb
#
class Foo
end

# <!-- rdoc-file=lib/foo.rb -->
# Doc Foo from foo.rb
#
%a{annotate:rdoc:source:from=lib/foo.rb}
class Foo
end

# <!-- rdoc-file=lib/bar.rb -->
# Doc of Foo from bar.rb
#
%a{annotate:rdoc:source:skip=lib/foo.rb}
class Foo
end
    RBS
  end

  def test_annotate_copy_annotation
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
# This is doc for Foo
class Foo
  # This is doc for Foo#foo
  def foo; end

  # This is doc for Foo.bar
  def self.bar; end
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
%a{annotate:rdoc:copy:Foo}
class A
  %a{annotate:rdoc:copy:Foo#foo}
  def b: () -> void

  %a{annotate:rdoc:copy:Foo.bar}
  alias c d
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
# <!-- rdoc-file=lib/foo.rb -->
# This is doc for Foo
#
%a{annotate:rdoc:copy:Foo}
class A
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - foo()
  # -->
  # This is doc for Foo#foo
  #
  %a{annotate:rdoc:copy:Foo#foo}
  def b: () -> void

  # <!--
  #   rdoc-file=lib/foo.rb
  #   - bar()
  # -->
  # This is doc for Foo.bar
  #
  %a{annotate:rdoc:copy:Foo.bar}
  alias c d
end
            RBS
  end

  def test_annotate_initialize
    source = load_source(
      {
        "foo.rb" => <<-RUBY,
class Foo
  # Doc for initialize
  def initialize; end
end
        RUBY
      }
    )

    decls = parse_rbs(<<-RBS)
class Foo
  def initialize: () -> void
end
    RBS

    annotator = RBS::Annotate::RDocAnnotator.new(source: source)
    annotator.annotate_decls(decls)

    assert_annotated_decls(<<-RBS, decls)
class Foo
  # <!--
  #   rdoc-file=lib/foo.rb
  #   - new()
  # -->
  # Doc for initialize
  #
  def initialize: () -> void
end
    RBS
  end
end
