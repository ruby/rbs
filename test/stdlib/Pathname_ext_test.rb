require_relative "test_helper"
require 'pathname'

class PathnameExtInstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'pathname'
  testing '::Pathname'

  def test_find
    assert_send_type '() { (Pathname) -> untyped } -> nil',
                     Pathname(__dir__), :find do end
    assert_send_type '(ignore_error: bool) -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find, ignore_error: true
    assert_send_type '(ignore_error: Symbol) -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find, ignore_error: :true
    assert_send_type '() -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find
  end

  def test_rmtree
    Dir.mktmpdir do |dir|
      target = Pathname(dir).join('target')
      target.mkdir
      assert_send_type '() -> Pathname',
                       target, :rmtree
    end
  end
end
