require "test_helper"

class SyntaxTest < Test::Unit::TestCase
  include TestHelper

  def test_core_syntax
    # Ensure no RBS::ParsingError, etc are raised during loading of core
    assert_nothing_raised do
      loader = RBS::EnvironmentLoader.new(repository: RBS::Repository.new(no_stdlib: false))
      RBS::Environment.from_loader(loader).resolve_type_names
    end
  end
end
