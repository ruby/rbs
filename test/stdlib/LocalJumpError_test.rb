require_relative "test_helper"

class LocalJumpErrorTest < StdlibTest
  target LocalJumpError

  def test_exit_value
    p = proc { break 3 }

    exception = begin
                  p []
                  nil
                rescue LocalJumpError => exn
                  exn
                end

    exception.exit_value
    exception.reason
  end
end
