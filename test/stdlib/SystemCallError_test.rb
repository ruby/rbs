require_relative "test_helper"

class SystemCallErrorTest < StdlibTest
  target SystemCallError
  using hook.refinement

  def test_initialize
    SystemCallError.new('hi')
    SystemCallError.new('hi', 0)
    SystemCallError.new('hi', 0, 'loc')
  end

  def test_errno
    begin
      raise Errno::ENOENT, 'test'
    rescue SystemCallError => exception
      exception.errno
    end

    begin
      raise SystemCallError, 'test'
    rescue SystemCallError => exception
      exception.errno
    end
  end
end
