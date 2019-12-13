require_relative "test_helper"

class UncaughtThrowErrorTest < StdlibTest
  target UncaughtThrowError
  using hook.refinement

  def test_tag
    begin
      throw :a
    rescue UncaughtThrowError => error
      error.tag
    end
  end
end
