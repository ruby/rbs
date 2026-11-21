require_relative "../test_helper"

require "socket"
require "tmpdir"

class UNIXServerInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::UNIXServer"

  def test_listen
    Dir.mktmpdir do |dir|
      UNIXServer.open(File.join(dir, "sock")) do |server|
        with_int(1) do |backlog|
          assert_send_type(
            "(::int) -> 0",
            server, :listen, backlog
          )
        end
      end
    end
  end
end
