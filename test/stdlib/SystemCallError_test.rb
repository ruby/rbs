require_relative "test_helper"

class SystemCallErrorTest < StdlibTest
  target SystemCallError
  using hook.refinement

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
