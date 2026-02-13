require "rbs"
require "rbs/ractor_pool"

type = RBS::Parser.parse_type("String")

r = Ractor.new do
  loop do
    msg = Ractor.receive
    pp msg
  end
end

pool = RBS::RactorPool.new(3) do |type|
  type.to_s
end

pp pool.map([type, type, type])

# type.instance_eval do
#   @location = nil
# end

# r.send(123, move: true)
# r.send(type, move: true)

# gets()

# pp type
