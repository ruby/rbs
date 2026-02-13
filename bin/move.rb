require "rbs"

type = RBS::Parser.parse_type("String")

r = Ractor.new do
  loop do
    msg = Ractor.receive
    pp msg
  end
end

# type.instance_eval do
#   @location = nil
# end

r.send(123, move: true)
r.send(type, move: true)

gets()

pp type
