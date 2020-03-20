require_relative "test_helper"

class RbConfigTest < StdlibTest
  target RbConfig

  using hook.refinement

  def test_ruby
    RbConfig.ruby
  end
end
