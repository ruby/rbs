Object.class_exec(1, "2", :hello) do |a, b, c|
  # @type var a: Integer
  # @type var b: String
  # @type var c: Symbol

  p a + 2
  p b + "2"
  c.id2name

  self.name
end

Object.module_exec(1, "2", :hello) do |a, b, c|
  # @type var a: Integer
  # @type var b: String
  # @type var c: Symbol

  p a + 2
  p b + "2"
  c.id2name

  self.name
end
