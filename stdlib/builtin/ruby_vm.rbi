# The [RubyVM](RubyVM) module provides some access to
# Ruby internals. This module is for very limited purposes, such as
# debugging, prototyping, and research. Normal users must not use it.
class RubyVM < Object
end

RubyVM::DEFAULT_PARAMS: Hash

RubyVM::INSTRUCTION_NAMES: Array

RubyVM::OPTS: Array

class RubyVM::InstructionSequence < Object
end
