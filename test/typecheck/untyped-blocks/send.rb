1.__send__(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  p x + 1
  p y + ""
end

1.send(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  p x + 1
  p y + ""
end

1.public_send(:foo, 1, "a") do |x, y|
  # @type var x: Integer
  # @type var y: String

  p x + 1
  p y + ""
end
