require_relative "test_helper"
require "securerandom"

class SecureRandomTest < StdlibTest
  target SecureRandom
  library "securerandom"
end
