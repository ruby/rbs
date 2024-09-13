require_relative 'test_helper'

class RefinementInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Refinement'

  REFINEMENT = module RefineString
    refine String do
    end
  end

  def test_target
    assert_send_type '() -> Module',
                     REFINEMENT, :target
    assert_send_type '() -> nil',
                     Refinement.new, :target
  end

  def test_import_methods
    assert_fn = method(:assert)

    Module.new {
      refine Integer do
        # Due to a bug in Ruby, you can't call `import_methods` outside of `refine`

        begin
          import_methods
        rescue
          assert_fn.call(true)
        else
          assert_fn.call(false, "import_methods accepts at least one argument?")
        end

        import_methods Module.new
        assert_fn.call(true)

        import_methods Module.new, Module.new
        assert_fn.call(true)
      end
    }
  end
end
