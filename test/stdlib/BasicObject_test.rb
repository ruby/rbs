class BasicObjectTest < StdlibTest
  target BasicObject
  using hook.refinement

  def test_instance_eval
    BasicObject.new.instance_eval { |x| x }
  end
end
