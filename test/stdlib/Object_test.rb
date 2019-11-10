class ObjectTest < StdlibTest
  target Object
  using hook.refinement

  def test_itself
    "itself".itself
  end
end
