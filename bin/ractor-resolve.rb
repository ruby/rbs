require "rbs"
require "benchmark"

env_loader = RBS::EnvironmentLoader.new

# env_loader.add(library: "pathname", version: nil)
# env_loader.add(library: "json", version: nil)
# env_loader.add(library: "monitor", version: nil)
# env_loader.add(library: "logger", version: nil)
# env_loader.add(library: "tsort", version: nil)
# env_loader.add(library: "uri", version: nil)
# env_loader.add(library: "dbm", version: nil)
# env_loader.add(library: "pstore", version: nil)
# env_loader.add(library: 'singleton')
# env_loader.add(library: 'shellwords', version: nil)
# env_loader.add(library: 'fileutils', version: nil)
# env_loader.add(library: 'find', version: nil)
# env_loader.add(library: 'digest', version: nil)
# env_loader.add(library: 'prettyprint', version: nil)
# env_loader.add(library: 'yaml', version: nil)
# env_loader.add(library: "psych", version: nil)
# env_loader.add(library: "securerandom", version: nil)
# env_loader.add(library: "prism", version: nil)
# env_loader.add(library: "strscan", version: "0")
# env_loader.add(library: "optparse", version: "0")
# env_loader.add(library: "rdoc", version: "0")
# env_loader.add(library: "ripper", version: "0")
# env_loader.add(library: "pp", version: "0")

path = Pathname("rbs_collection.lock.yaml")
lockfile = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: path, data: YAML.load_file(path))
env_loader.add_collection(lockfile)
env_loader.add(path: Pathname("sig"))

class EnumerationPool
  attr_reader :worker_port

  attr_reader :workers

  def initialize(enumerators)
    @worker_port = Ractor::Port.new

    @workers = enumerators.map do |enumerator|
      Ractor.new(worker_port, enumerator) do |worker_port, enum|
        # enum = Ractor.receive
        worker_port << Ractor.current
        count = 0
        iters = 0
        started_at = nil
        loop do
          iters += 1
          msg = Ractor.receive
          started_at ||= Time.now
          case msg
          when :result
            puts "Enumerated #{count} declarations in #{Time.now - started_at} secs, #{iters} iterations"
            break [enum.names, enum.aliases]
          else
            decls = msg
            decls.each do |decl|
              enum.enumerate(decl, RBS::Namespace.root, nil)
              count += 1
            end
            worker_port << Ractor.current
          end
        end
      end.tap do
        # _1.send(enumerator, move: true)
      end
    end
  end

  def each(decls)
    thread = Thread.new do
      decls.each_slice(10) do
        worker = worker_port.receive
        worker.send _1.freeze
      end
    end

    thread.join
  end

  def values
    workers.map do |worker|
      worker << :result
      worker.value
    end
  end
end

class ResolverPool
  attr_reader :worker_port, :result_port

  attr_reader :workers

  def initialize(pairs)
    @worker_port = Ractor::Port.new
    @result_port = Ractor::Port.new

    @workers = pairs.map do |type_name_resolver_, table_|
      Ractor.new(worker_port, result_port) do |worker_port, result_port|
        type_name_resolver, table = Ractor.receive
        worker_port << Ractor.current
        count = 0
        iters = 0
        started_at = Time.now
        loop do
          iters += 1
          msg = Ractor.receive
          case msg
          when :result
            puts "Resolved #{count} declarations in #{Time.now - started_at} secs #{iters} iterations"
            break table
          else
            decls, dirs = msg
            resolver = RBS::MultithreadLoader::ASTResolver.build(type_name_resolver, table, dirs)
            decls_ = decls.map do |decl|
              count += 1
              resolver.resolve_decl(decl, nil, RBS::Namespace.root)

              # Ractor.make_shareable(decl, copy: true)
            end
            result_port.send decls_, move: true
            worker_port << Ractor.current
          end
        end
      end.tap do
        _1.send([type_name_resolver_, table_], move: false)
      end
    end
  end

  def map(srcs)
    thread = Thread.new do
      srcs.each do |src|
        worker = worker_port.receive
        pair = [src.declarations.freeze, src.directives.freeze].freeze
        Ractor.make_shareable(pair) or raise
        worker.send(pair)
      end
    end

    results = []
    while srcs.size > results.size
      results.push result_port.receive
    end

    workers.each do |worker|
      worker << :result
    end

    thread.join

    results.flatten
  end
end

Ractor.new {}.join

size = 4

require "optparse"

OptionParser.new do |opts|
  opts.on("-jN", "--jobs=N", Integer, "Number of ractors to use") do |n|
    size = n.to_i
  end
end.parse!(ARGV)

srcs = []
buffers = []

read = Benchmark.realtime do
  env_loader.each_signature_file do |source, path|
    buffers << RBS::Buffer.new(name: path, content: path.read(encoding: "UTF-8")).finalize
  end
end
puts "Read #{buffers.size} files in #{read}s"

seq = Benchmark.realtime do
  buffers.each do |buffer|
    buffer, dirs, decls = RBS::Parser.parse_signature(buffer)
    srcs << RBS::Source::RBS.new(buffer, dirs, decls)
  end
end
puts "Single thread parse time: #{seq}s"

# send_port = Ractor::Port.new()

# send_ractor = Ractor.new(send_port) do |send_port|
#   while task = Ractor.receive
#     RBS::Parser.parse_signature(task.buffer)
#     send_port.send(task)
#   end

#   send_port.send(nil)
# end

srcs.each do Ractor.make_shareable(_1) or raise end

# s = Benchmark.realtime do
#   t = Thread.new do
#     srcs.each do |src|
#       send_ractor.send(src)
#     end
#     send_ractor.send(nil)
#   end

#   while send_port.receive
#   end

#   t.join
# end
# puts "Sending #{srcs.size} sources to ractor time: #{s}s"

lll = Benchmark.realtime do
  RBS::RactorPool.map(srcs, size) do |src|
    buffer, dirs, decls = RBS::Parser.parse_signature(src.buffer)
    # Ractor.shareable?(decls) or raise
    RBS::Source::RBS.new(buffer, dirs, decls).freeze
    # src
  end
end
puts "Ractor parse time: #{lll}s"

# GC.disable

# lo = Benchmark.realtime do
#   srcs.concat RBS::RactorPool.map(buffers.freeze, size) {|buffer|
#     buffer, dirs, decls = RBS::Parser.parse_signature(buffer)
#     # tuple = [buffer, dirs, decls].freeze
#     # unless Ractor.shareable?(tuple)
#     #   unless Ractor.shareable?(tuple[0])
#     #     puts "Buffer is not shareable: #{buffer.inspect}"
#     #   end
#     #   unless Ractor.shareable?(tuple[1])
#     #     puts "Dirs is not shareable: #{tuple[1].inspect}"
#     #   end
#     #   unless Ractor.shareable?(tuple[2])
#     #     puts "Decls is not shareable: #{tuple[2].inspect}"
#     #   end
#     # end
#     # tuple
#     # dirs = [].freeze
#     # decls = [].freeze
#     # Ractor.shareable?(dirs) or raise
#     # Ractor.make_shareable(dirs) or raise

#     src = RBS::Source::RBS.new(buffer, dirs, decls)

#     # Ractor.make_shareable(src) or raise
# #
#     # unless Ractor.shareable?(src)
#     #   unless Ractor.shareable?(src.buffer)
#     #     raise "Buffer is not shareable: #{src.buffer.inspect}"
#     #   end
#     #   unless Ractor.shareable?(src.directives)
#     #     raise "Dirs is not shareable: #{src.directives.inspect}"
#     #   end
#     #   unless Ractor.shareable?(src.declarations)
#     #     raise "Decls is not shareable: #{src.declarations.inspect}"
#     #   end
#     #   raise "Source is not shareable: #{src.inspect}"
#     # end
#     # src
#     # RBS::Source::RBS.new(buffer, [], [])
#     # Ractor.shareable?(src) or raise
#     # src
#     # Ractor.make_shareable(src) or raise
#     # [buffer, dirs, decls]
#   }
# end
# # srcs.map! {|(buffer, dirs, decls)|
# #   RBS::Source::RBS.new(buffer, dirs, decls)
# # }

# puts "Load #{srcs.size} files in #{lo}ms in #{size} ractors"

exit

# srcs.clear

ra = Benchmark.realtime do
  # break
  type_name_enumeration = EnumerationPool.new(size.times.map { RBS::MultithreadLoader::TypeNameEnumerator.new() })
  type_name_enumeration.each(srcs.flat_map(&:declarations))

  enums = type_name_enumeration.values

  all_names = Set[]
  aliases = {}

  enums.each do |ns, as|
    all_names.merge(ns)
    aliases.merge!(as)
  end

  all_names.freeze
  aliases.freeze

  # binding.irb

  # pp all_names.include?(RBS::TypeName.parse("::UserOffering::ActiveRecord_Associations_CollectionProxy"))

  pairs = nil
  resolvers = size.times.map { RBS::Resolver::TypeNameResolver.new(all_names, aliases.dup) }
  table = RBS::Environment::UseMap::Table.new()
  table.known_types.merge(all_names)
  table.known_types.merge(aliases.each_key)
  table.compute_children
  pairs = resolvers.map {|resolver|
    [resolver, table]
  }

  GC.disable

  resolve_pool = ResolverPool.new(pairs)

  results = []

  results.concat resolve_pool.map(srcs)

  env = RBS::Environment.new
  results.each do |decl|
    env.insert_rbs_decl(decl, context: nil, namespace: RBS::Namespace.root)
  end
end

puts "Ractor resolve time: #{ra}ms"

ss = Benchmark.realtime do
  env = RBS::Environment.new
  srcs.each do |src|
    env.add_source src
  end
  env.resolve_type_names
end

puts "Single thread resolve time: #{ss}ms"
