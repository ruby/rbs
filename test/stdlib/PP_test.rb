require_relative "test_helper"
require "pp"

class PPSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "pp"
  testing "singleton(::PP)"

  def test_pp
    assert_send_type "(::PP::_PrettyPrint obj, ?::PP::_LeftShift out, ?::Integer width) -> untyped",
                     PP, :pp, Object.new, ''.dup

    IO.pipe do |r, w|
      assert_send_type "(::PP::_PrettyPrint obj, ?::PP::_LeftShift out, ?::Integer width) -> untyped",
                      PP, :pp, Object.new, w
    end
  end

  def test_width_for
    assert_send_type "(untyped out) -> ::Integer",
                     PP, :width_for, Object.new
    assert_send_type "(untyped out) -> ::Integer",
                     PP, :width_for, $stdout
   end

  def test_singleline_pp
    assert_send_type "(::PP::_PrettyPrint obj, ?::PP::_LeftShift out) -> untyped",
                     PP, :singleline_pp, Object.new
    assert_send_type "(::PP::_PrettyPrint obj, ?::PP::_LeftShift out) -> untyped",
                     PP, :singleline_pp, Object.new, ''.dup
  end

  def test_mcall
    assert_send_type "(untyped obj, ::Module mod, ::interned meth, *untyped args) -> untyped",
                     PP, :mcall, self, Kernel, :class
    assert_send_type "(untyped obj, ::Module mod, ::interned meth, *untyped args) -> untyped",
                     PP, :mcall, 1, Integer, :+, 2
    assert_send_type "(untyped obj, ::Module mod, ::interned meth, *untyped args) { (*untyped, **untyped) -> untyped } -> untyped",
                     PP, :mcall, 1, Kernel, :tap do end
  end
end

class PP::PPMethodsTest < Test::Unit::TestCase
  include TypeAssertions

  library "pp"
  testing "::PP::PPMethods"

  def test_guard_inspect_key
    assert_send_type "() { () -> untyped } -> void",
                     PP.new, :guard_inspect_key do end
  end

  def test_check_inspect_key
    assert_send_type "(::PP::_PrettyPrint id) -> bool",
                     PP.new, :check_inspect_key, Object.new
  end

  def test_push_inspect_key
    assert_send_type "(::PP::_PrettyPrint id) -> void",
                     PP.new, :push_inspect_key, Object.new
  end

  def test_pop_inspect_key
    assert_send_type "(::PP::_PrettyPrint id) -> void",
                     PP.new, :pop_inspect_key, Object.new
  end

  def test_pp
    assert_send_type "(::PP::_PrettyPrint obj) -> untyped",
                     PP.new, :pp, Object.new
  end

  def test_object_group
    assert_send_type "(untyped obj) { () -> untyped } -> ::Integer",
                     PP.new, :object_group, Object.new do end
  end

  def test_object_address_group
    assert_send_type "(untyped obj) { () -> untyped } -> ::Integer",
                     PP.new, :object_address_group, Object.new do end
  end

  def test_comma_breakable
    assert_send_type "() -> void",
                     PP.new, :comma_breakable
  end

  def test_seplist
    assert_send_type "(untyped list) { (*untyped, **untyped) -> void } -> void",
                     PP.new, :seplist, [] do end
    assert_send_type "(untyped list, ^() -> void? sep) { (*untyped, **untyped) -> void } -> void",
                     PP.new, :seplist, [], lambda {} do end
    assert_send_type "(untyped list, ^() -> void? sep, ::interned iter_method) { (*untyped, **untyped) -> void } -> void",
                     PP.new, :seplist, [], lambda {}, :each do end
  end

  def test_pp_object
    assert_send_type "(untyped obj) -> untyped",
                     PP.new, :pp_object, Object.new
  end

  def test_pp_hash
    assert_send_type "(untyped obj) -> untyped",
                     PP.new, :pp_hash, {}
  end
end

class PP::ObjectMixinTest < Test::Unit::TestCase
  include TypeAssertions

  library "pp"
  testing "::PP::ObjectMixin"

  def test_pretty_print
    assert_send_type "(PP q) -> untyped",
                     Object.new, :pretty_print, PP.new
  end

  def test_pretty_print_cycle
    assert_send_type "(PP q) -> untyped",
                     Object.new, :pretty_print_cycle, PP.new
  end

  def test_pretty_print_instance_variables
    assert_send_type "() -> Array[Symbol]",
                     Object.new, :pretty_print_instance_variables
  end

  def test_pretty_print_inspect
    has_pretty_print = Class.new do
      def pretty_print(q)
        'ok'
      end
    end
    assert_send_type "() -> untyped",
                     has_pretty_print.new, :pretty_print_inspect
  end
end
