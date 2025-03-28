require "test_helper"

return if ENV["RUBY"]

class RDocSourceTest < Test::Unit::TestCase
  def load_source(files)
    Dir.mktmpdir do |dir|
      path = Pathname(dir)

      (path + "lib").mkdir

      files.each do |file, content|
        (path + "lib" + file).write(content)
      end

      system(
        "rdoc -q --ri -o #{path}/doc #{path}/lib",
      )

      source = RBS::Annotate::RDocSource.new()
      source.with_system_dir = false
      source.extra_dirs << (path + "doc")

      source.load()

      source
    end
  end

  def test_load_class
    source = load_source(
      {
        "foo.rb" => <<-RUBY
# Document for Hello1
class Hello1
end

class Hello2
end

# Document (1) for Hello3
class Hello3
end

# Document (2) for Hello3
class Hello3
end
        RUBY
      }
    )

    assert_nil source.find_class(RBS::TypeName.parse("Hello0"))

    source.find_class(RBS::TypeName.parse("Hello1")).tap do |klss|
      assert_instance_of Array, klss

      assert_equal 1, klss.size
      klss[0].tap do |klass|
        assert_predicate klass, :documented?
        assert_equal 1, klass.comment.parse.parts.size

        assert_nil RBS::Annotate::Formatter.translate(klass.comment.parse)
        assert_equal "Document for Hello1", RBS::Annotate::Formatter.translate(klass.comment.parse.parts[0])
      end
    end

    source.find_class(RBS::TypeName.parse("Hello2")).tap do |klss|
      assert_instance_of Array, klss

      assert_equal 1, klss.size
      klss[0].tap do |klass|
        refute_predicate klass, :documented?

        assert_nil RBS::Annotate::Formatter.translate(klass.comment.parse)
        assert_equal "", RBS::Annotate::Formatter.translate(klass.comment.parse.parts[0])
      end
    end

    source.find_class(RBS::TypeName.parse("Hello3")).tap do |klss|
      assert_instance_of Array, klss

      assert_equal 1, klss.size
      klss[0].tap do |klass|
        assert_predicate klass, :documented?
        assert_equal 2, klass.comment.parse.parts.size

        assert_equal "Document (1) for Hello3", RBS::Annotate::Formatter.translate(klass.comment.parse.parts[0])
        assert_equal "Document (2) for Hello3", RBS::Annotate::Formatter.translate(klass.comment.parse.parts[1])
      end
    end
  end

  def test_load_const
    source = load_source(
      {
        "foo.rb" => <<-RUBY
# Doc for FOO
FOO = "123"

class Hello
  # Doc for Hello::VERSION
  VERSION = "1.0.2"
end
        RUBY
      }
    )

    source.find_const(RBS::TypeName.parse("FOO")).tap do |consts|
      assert_instance_of Array, consts

      assert_equal 1, consts.size
      consts[0].tap do |const|
        assert_equal "FOO", const.name
        assert_equal "Doc for FOO", RBS::Annotate::Formatter.translate(const.comment.parse)
      end
    end

    source.find_const(RBS::TypeName.parse("Hello::VERSION")).tap do |consts|
      assert_instance_of Array, consts

      assert_equal 1, consts.size
      consts[0].tap do |const|
        assert_equal "VERSION", const.name
        assert_equal "Doc for Hello::VERSION", RBS::Annotate::Formatter.translate(const.comment.parse)
      end
    end

    assert_nil source.find_const(RBS::TypeName.parse("Hello::World"))

    assert_nil source.find_const(RBS::TypeName.parse("Hello"))
  end

  def test_load_method
    source = load_source(
      {
        "foo.rb" => <<-RUBY
class Foo
  # Doc for m1
  def m1; end

  # Doc for m2
  alias m2 m1

  # Doc for m4
  def self.m4; end

  class <<self
    # Doc for m5
    def m5; end
  end
end
        RUBY
      }
    )

    source.find_method(RBS::TypeName.parse("Foo"), instance_method: :m1).tap do |ms|
      assert_equal 1, ms.size

      ms[0].tap do |m|
        assert_equal "m1", m.name
        assert_equal "Doc for m1", RBS::Annotate::Formatter.translate(m.comment.parse)
      end
    end

    source.find_method(RBS::TypeName.parse("Foo"), instance_method: :m2).tap do |ms|
      assert_equal 1, ms.size

      ms[0].tap do |m|
        assert_equal "m2", m.name
        assert_equal "Doc for m2", RBS::Annotate::Formatter.translate(m.comment.parse)
        assert_equal "m1", m.is_alias_for.name
      end
    end

    assert_nil source.find_method(RBS::TypeName.parse("Foo"), instance_method: :m3)

    source.find_method(RBS::TypeName.parse("Foo"), singleton_method: :m4).tap do |ms|
      assert_equal 1, ms.size

      ms[0].tap do |m|
        assert_equal "m4", m.name
        assert_equal "Doc for m4", RBS::Annotate::Formatter.translate(m.comment.parse)
      end
    end

    source.find_method(RBS::TypeName.parse("Foo"), singleton_method: :m5).tap do |ms|
      assert_equal 1, ms.size

      ms[0].tap do |m|
        assert_equal "m5", m.name
        assert_equal "Doc for m5", RBS::Annotate::Formatter.translate(m.comment.parse)
      end
    end
  end

  def test_load_attributes
    source = load_source(
      {
        "foo.rb" => <<-RUBY
class Foo
  # Doc for foo
  attr_reader :foo

  # Doc for bar and baz
  attr_accessor :bar, :baz

  class <<self
    # Doc for aaa
    attr_writer :aaa
  end
end
        RUBY
      }
    )

    source.find_attribute(RBS::TypeName.parse("Foo"), :foo, singleton: false).tap do |attrs|
      assert_equal 1, attrs.size

      attrs[0].tap do |attr|
        assert_equal "foo", attr.name
        assert_equal "Doc for foo", RBS::Annotate::Formatter.translate(attr.comment.parse)
        assert_equal "R", attr.rw
      end
    end

    source.find_attribute(RBS::TypeName.parse("Foo"), :bar, singleton: false).tap do |attrs|
      assert_equal 1, attrs.size

      attrs[0].tap do |attr|
        assert_equal "bar", attr.name
        assert_equal "Doc for bar and baz", RBS::Annotate::Formatter.translate(attr.comment.parse)
        assert_equal "RW", attr.rw
      end
    end

    source.find_attribute(RBS::TypeName.parse("Foo"), :baz, singleton: false).tap do |attrs|
      assert_equal 1, attrs.size

      attrs[0].tap do |attr|
        assert_equal "baz", attr.name
        assert_equal "Doc for bar and baz", RBS::Annotate::Formatter.translate(attr.comment.parse)
        assert_equal "RW", attr.rw
      end
    end
  end
end
