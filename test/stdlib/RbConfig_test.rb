require_relative "test_helper"

require 'rbconfig'

class RbConfigTest < StdlibTest
  target RbConfig
  library "rb_config"

  using hook.refinement

  def test_config
    RbConfig::CONFIG
  end

  def test_destdir
    RbConfig::DESTDIR
  end
end
