class BasicObjectTest < StdlibTest
  target BasicObject
  using hook.refinement

  def test_instance_eval
    BasicObject.new.instance_eval { |x| x }
  end

  def test_instance_exec
    BasicObject.new.instance_exec(1) { 10 }
    BasicObject.new.instance_exec(1,2,3) { 10 }
  end
end
