require "test_helper"

class RBS::Annotate::AnnotationsTest < Test::Unit::TestCase
  def an(string)
    RBS::AST::Annotation.new(location: nil, string: string)
  end

  def test_skip
    RBS::Annotate::Annotations.parse(an("annotate:rdoc:skip")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Skip, a
      refute_predicate a, :skip_children
    end

    RBS::Annotate::Annotations.parse(an("annotate:rdoc:skip:all")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Skip, a
      assert_predicate a, :skip_children
    end
  end

  def test_source
    RBS::Annotate::Annotations.parse(an("annotate:rdoc:source:from=ext/pathname")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Source, a
      assert_equal "ext/pathname", a.include_source
      assert_nil a.skip_source
    end

    RBS::Annotate::Annotations.parse(an("annotate:rdoc:source:skip=ext/pathname/doc")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Source, a
      assert_nil a.include_source
      assert_equal "ext/pathname/doc", a.skip_source
    end
  end

  def test_copy
    RBS::Annotate::Annotations.parse(an("annotate:rdoc:copy:Bar#baz")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Copy, a

      assert_equal TypeName("Bar"), a.type_name
      refute_predicate a, :singleton?
      assert_equal :baz, a.method_name
    end

    RBS::Annotate::Annotations.parse(an("annotate:rdoc:copy:Bar.baz")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Copy, a

      assert_equal TypeName("Bar"), a.type_name
      assert_predicate a, :singleton?
      assert_equal :baz, a.method_name
    end

    RBS::Annotate::Annotations.parse(an("annotate:rdoc:copy:Bar")).tap do |a|
      assert_instance_of RBS::Annotate::Annotations::Copy, a

      assert_equal TypeName("Bar"), a.type_name
      refute_predicate a, :singleton?
      assert_nil a.method_name
    end
  end
end
