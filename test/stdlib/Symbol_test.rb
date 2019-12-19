require_relative "test_helper"

class SymbolTest < StdlibTest
  target Symbol
  using hook.refinement

  if RUBY_27_OR_LATER
    def test_start_with?
      :a.start_with?("a")
      :a.start_with?("b")
    end
  end
end
