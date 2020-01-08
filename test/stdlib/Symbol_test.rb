require_relative "test_helper"

class SymbolTest < StdlibTest
  target Symbol
  using hook.refinement

  def test_all_symbols
    Symbol.all_symbols
  end

  if RUBY_27_OR_LATER
    def test_end_with?
      :a.end_with?("a")
      :a.end_with?("b")
    end

    def test_start_with?
      :a.start_with?("a")
      :a.start_with?("b")
    end
  end
end
