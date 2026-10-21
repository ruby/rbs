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
    test = self

    Module.new {
      refine Integer do
        # Due to a bug in Ruby, you can't call `import_methods` outside of `refine`.
        # Calling it with modules through `assert_send_type` also crashes the VM
        # (`cref_replace_with_duplicated_cref_each_frame: unreachable`), so only the
        # no-argument case is checked here.
        test.refute_send_type '() -> untyped',
                              self, :import_methods
      end
    }
  end
end
