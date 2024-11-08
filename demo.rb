require 'rubyvm/instruction_sequence'

# Example Ruby code
code = <<~RUBY
  class C
    def x
      [1, 2, 3]
    end

    def hash
      [1, 2, 3].hash
    end
  end
RUBY

# Compile the Ruby code into instruction sequences
iseq = RubyVM::InstructionSequence.compile(code)

# Disassemble the instruction sequences
disassembled_code = iseq.disasm

# Print disassembled code
puts disassembled_code
