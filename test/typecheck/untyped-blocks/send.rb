1.__send__(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  x + 1
  y + ""
end

1.send(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  x + 1
  y + ""
end

1.public_send(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  x + 1
  y + ""
end
