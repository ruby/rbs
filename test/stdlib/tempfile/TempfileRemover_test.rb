require_relative "../test_helper"
require 'tempfile'

class TempfileRemoverSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "tempfile"
  testing "singleton(::Tempfile::Remover)"

  def test_initialize
    assert_send_type "(::Tempfile tmpfile) -> void",
                     Tempfile::Remover, :new, Tempfile.new('README.md')
  end
end

class TempfileRemoverTest < Test::Unit::TestCase
  include TypeAssertions

  library "tempfile"
  testing "::Tempfile::Remover"

  def test_call
    assert_send_type "(*untyped args) -> void",
                     Tempfile::Remover.new(Tempfile.new('README.md')),
                     :call
  end
end
