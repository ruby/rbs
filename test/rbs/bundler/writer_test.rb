require "test_helper"

class RBS::Bundle::WriterTest < Test::Unit::TestCase
  include RBS

  def writer(**sources)
    writer = Bundle::Writer.new()
    sources.each do |name, content|
      buffer = Buffer.new(content: content, name: name)
      _, dirs, decls = Parser.parse_signature(buffer)
      writer.add_buffer(name, buffer, dirs, decls)
    end

    writer.as_json()
  end

  def test_buffer
    env = RBS::Environment.new
    loader = RBS::EnvironmentLoader.new()
    loader.load(env: env)
    env = env.resolve_type_names()

    writer = Bundle::Writer.new()

    env.signatures.each do |buffer, (dirs, decls)|
      writer.add_buffer(buffer.name.to_s, buffer, dirs, decls)
    end

    path = Pathname("tmp/rbs.json")

    path.write(JSON.generate(writer.as_json))

    loader = Bundle::Loader.new(JSON.parse(path.read)) do |name|
      Buffer.new(content: File.read(name), name: name)
    end

    loader.load do |buffer, dirs, decls|
      
    end
  end
end
