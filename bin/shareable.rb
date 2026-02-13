require "rbs"
require "objspace"

# RBS::Parser.parse_method_type("(String) { () -> untyped } -> void")

def shareable?(obj)
  pp(obj.to_s => Ractor.shareable?(obj))
end

def parse_file(file)
  buffer = RBS::Buffer.new(name: Pathname(file), content: Pathname(file).read).finalize
  RBS::Parser.parse_signature(buffer)
end

def find_unshareable_object(object, path: [])
  if path.size > 100
    return path
  end

  if Ractor.shareable?(object)
    return
  end

  path << object

  ObjectSpace.reachable_objects_from(object).each do |child|
    if find_unshareable_object(child, path: path)
      return path
    end
  end

  path.pop
end

object = parse_file("core/nil_class.rbs")
# object = RBS::Parser.parse_type("_DataClass")

if unshareable = find_unshareable_object(object)
  # pp unshareable

  pp unshareable.last.frozen?

  binding.irb

  pp unshareable.reverse.take(4)
end
