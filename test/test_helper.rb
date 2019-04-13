$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "ruby/signature"
require "tmpdir"
require 'minitest/reporters'

MiniTest::Reporters.use!

module TestHelper
  def parse_type(string, variables: Set.new)
    Ruby::Signature::Parser.parse_type(string, variables: variables)
  end
end

require "minitest/autorun"
