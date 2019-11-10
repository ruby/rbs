class KernelTest < StdlibTest
  target Kernel
  using hook.refinement

  def test_p
    $stdout = StringIO.new
    p 1
    p 'a', 2
  ensure
    $stdout = STDOUT
  end
end
