class NilClassTest < StdlibTest
  target NilClass
  using hook.refinement

  def test_to_i
    nil.to_i
  end

  def test_nil?
    nil.nil?
  end

  define_method "test_&" do
    nil & true
  end
end
