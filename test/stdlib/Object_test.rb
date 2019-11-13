class ObjectTest < StdlibTest
  target Object
  using hook.refinement

  def test_itself
    "itself".itself
  end

  def test_respond_to?
    Object.new.respond_to?(:to_s)
    Object.new.respond_to?('to_s')
    Object.new.respond_to?('to_s', true)
  end
end
