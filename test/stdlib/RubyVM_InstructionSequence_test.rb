require_relative "test_helper"

class RubyVM::InstructionSequenceSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::RubyVM::InstructionSequence)"

  def test_of
    assert_send_type "(::Method body) -> ::RubyVM::InstructionSequence",
                     RubyVM::InstructionSequence, :of, method(:test_of)
    assert_send_type "(::UnboundMethod body) -> ::RubyVM::InstructionSequence",
                     RubyVM::InstructionSequence, :of, self.class.instance_method(:test_of)
    assert_send_type "(::Proc body) -> ::RubyVM::InstructionSequence",
                     RubyVM::InstructionSequence, :of, -> { }
  end
end
