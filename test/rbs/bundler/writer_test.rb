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

  def test_benchmark
    require "benchmark"

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

    Benchmark.bmbm do
      _1.report "EnvironmentLoader" do
        env = RBS::Environment.new
        loader = RBS::EnvironmentLoader.new()
        loader.load(env: env)
        env = env.resolve_type_names()
      end

      _1.report "Bundle::Loader" do
        json = JSON.parse(path.read)
        loader = Bundle::Loader.new(json) do |name|
          Buffer.new(content: File.read(name), name: name)
        end

        env2 = RBS::Environment.new

        loader.load do |buffer, dirs, decls|
          env2.add_signature(buffer: buffer, directives: dirs, decls: decls)
        end
      end

      _1.report "Loading JSON" do
        JSON.parse(path.read)
      end

      _1.report "Loading JSON and constructing AST" do
        json = JSON.parse(path.read)
        loader = Bundle::Loader.new(json) do |name|
          Buffer.new(content: File.read(name), name: name)
        end

        loader.load do |buffer, dirs, decls|
        end
      end
    end
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

    env2 = RBS::Environment.new

    loader.load do |buffer, dirs, decls|
      env2.add_signature(buffer: buffer, directives: dirs, decls: decls)
    end

    bufs1 = env.buffers.map { _1.name.to_s }.sort
    bufs2 = env2.buffers.map { _1.name.to_s }.sort

    assert_equal bufs1, bufs2

    bufs1.each do |name|
      buf1 = env.buffers.find { _1.name.to_s == name } or raise
      dirs1, decls1 = env.signatures[buf1]

      buf2 = env2.buffers.find { _1.name.to_s == name } or raise
      dirs2, decls2 = env2.signatures[buf2]

      output1 = StringIO.new
      RBS::Writer.new(out: output1).tap do |w|
        w.write(dirs1 + decls1)
      end
      output2 = StringIO.new
      RBS::Writer.new(out: output2).tap do |w|
        w.write(dirs2 + decls2)
      end

      lines1 = output1.string.lines
      lines2 = output2.string.lines

      if lines1 != lines2
        lines1.zip(lines2).each.with_index do |(l1, l2), i|
          assert_equal l1, l2
        end
      else
        assert true
      end
    end
  end
end
