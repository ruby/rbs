require_relative "test_helper"
require "securerandom"

class SecureRandomTest < StdlibTest
  target SecureRandom
  library "securerandom"

  def test_alphanumeric
    SecureRandom.alphanumeric
    SecureRandom.alphanumeric(nil)
    SecureRandom.alphanumeric(4)
  end
end
