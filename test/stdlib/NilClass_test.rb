class NilClassTest < StdlibTest
  target NilClass
  using hook.refinement

  def test_to_i
    nil.to_i
  end
end
