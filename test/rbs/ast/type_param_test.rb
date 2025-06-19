require "test_helper"

class RBS::AST::TypeParamTest < Test::Unit::TestCase
  include TestHelper

  include RBS::AST

  def parse_type(string, variables: [:A, :B, :C, :D, :E])
    RBS::Parser.parse_type(string, variables: variables)
  end

  def test_application1
    params = [
      TypeParam.new(name: :A, variance: :inout, upper_bound: nil, lower_bound: nil, location: nil),
      TypeParam.new(name: :B, variance: :inout, upper_bound: nil, lower_bound: nil, default_type: parse_type("::String"), location: nil),
    ]

    TypeParam.application(params, []).tap do |s|
      assert_equal parse_type("untyped"), s.mapping[:A]
      assert_equal parse_type("::String"), s.mapping[:B]
    end

    TypeParam.application(params, [parse_type("::Integer")]).tap do |s|
      assert_equal parse_type("::Integer"), s.mapping[:A]
      assert_equal parse_type("::String"), s.mapping[:B]
    end

    TypeParam.application(params, [parse_type("::Integer"), parse_type("::Symbol"), parse_type("bool")]).tap do |s|
      assert_equal parse_type("::Integer"), s.mapping[:A]
      assert_equal parse_type("::Symbol"), s.mapping[:B]
    end
  end

  def test_application2
    params = [
      TypeParam.new(name: :A, variance: :inout, upper_bound: nil, lower_bound: nil, location: nil),
      TypeParam.new(name: :B, variance: :inout, upper_bound: nil, lower_bound: nil, default_type: parse_type("::Array[A]"), location: nil),
      TypeParam.new(name: :C, variance: :inout, upper_bound: nil, lower_bound: nil, default_type: parse_type("::Array[B]"), location: nil),
    ]

    TypeParam.application(params, []).tap do |s|
      assert_equal parse_type("untyped"), s.mapping[:A]
      assert_equal parse_type("::Array[untyped]"), s.mapping[:B]
      assert_equal parse_type("::Array[untyped]"), s.mapping[:C]
    end

    TypeParam.application(params, [parse_type("::Integer")]).tap do |s|
      assert_equal parse_type("::Integer"), s.mapping[:A]
      assert_equal parse_type("::Array[::Integer]"), s.mapping[:B]
      assert_equal parse_type("::Array[untyped]"), s.mapping[:C]
    end
  end

  def test_normalize_args
    params = [
      TypeParam.new(name: :A, variance: :inout, upper_bound: nil, lower_bound: nil, location: nil),
      TypeParam.new(name: :B, variance: :inout, upper_bound: nil, lower_bound: nil, default_type: parse_type("::Array[A]"), location: nil),
      TypeParam.new(name: :C, variance: :inout, upper_bound: nil, lower_bound: nil, default_type: parse_type("::Array[B]"), location: nil),
    ]

    TypeParam.normalize_args(params, []).tap do |args|
      assert_equal [], args.map(&:to_s)
    end

    TypeParam.normalize_args(params, [parse_type("::Integer")]).tap do |args|
      assert_equal ["::Integer", "::Array[::Integer]", "::Array[::Array[::Integer]]"], args.map(&:to_s)
    end
  end
end
