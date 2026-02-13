require "rbs"
require "benchmark"

env_loader = RBS::EnvironmentLoader.new

env_loader.add(library: "pathname", version: nil)
env_loader.add(library: "json", version: nil)
env_loader.add(library: "monitor", version: nil)
env_loader.add(library: "logger", version: nil)
env_loader.add(library: "tsort", version: nil)
env_loader.add(library: "uri", version: nil)
env_loader.add(library: "dbm", version: nil)
env_loader.add(library: "pstore", version: nil)
env_loader.add(library: 'singleton')
env_loader.add(library: 'shellwords', version: nil)
env_loader.add(library: 'fileutils', version: nil)
env_loader.add(library: 'find', version: nil)
env_loader.add(library: 'digest', version: nil)
env_loader.add(library: 'prettyprint', version: nil)
env_loader.add(library: 'yaml', version: nil)
env_loader.add(library: "psych", version: nil)
env_loader.add(library: "securerandom", version: nil)
env_loader.add(library: "prism", version: nil)
env_loader.add(library: "strscan", version: "0")
env_loader.add(library: "optparse", version: "0")
env_loader.add(library: "rdoc", version: "0")
env_loader.add(library: "ripper", version: "0")
env_loader.add(library: "pp", version: "0")
env_loader.add(path: Pathname("sig"))

class EnumerationPool
  attr_reader :worker_port

  attr_reader :workers

  def initialize(enumerators)
    @worker_port = Ractor::Port.new

    @workers = enumerators.map do |enumerator|
      Ractor.new(worker_port, enumerator) do |worker_port, enum|
        worker_port << Ractor.current
        loop do
          msg = Ractor.receive
          case msg
          when :result
            break enum
          else
            decls = msg
            decls.each do |decl|
              enum.enumerate(decl, RBS::Namespace.root, nil)
            end
            worker_port << Ractor.current
          end
        end
      end
    end
  end

  def each(srcs)
    thread = Thread.new do
      srcs.each do
        worker = worker_port.receive
        worker.send _1.declarations, move: true
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

    @workers = pairs.map do |type_name_resolver, table|
      Ractor.new(worker_port, result_port, type_name_resolver, table) do |worker_port, result_port, type_name_resolver, table|
        worker_port << Ractor.current
        loop do
          msg = Ractor.receive
          case msg
          when :result
            break table
          else
            decls = msg.declarations
            dirs = msg.directives
            resolver = RBS::MultithreadLoader::ASTResolver.build(type_name_resolver, table, dirs)
            decls_ = decls.map do |decl|
              resolver.resolve_decl(decl, nil, RBS::Namespace.root)
            end
            result_port.send decls_, move: true
            worker_port << Ractor.current
          end
        end
      end
    end
  end

  def map(srcs)
    thread = Thread.new do
      srcs.each do
        worker = worker_port.receive
        worker << _1
      end
    end

    results = []
    while srcs.size > results.size
      results << result_port.receive
    end

    thread.join

    results
  end
end

size = 4
srcs = []

env_loader.each_signature do |src, path, buffer, decls, dirs|
  srcs << RBS::Source::RBS.new(buffer, dirs, decls)
end

ra = Benchmark.realtime do
  type_name_enumeration = EnumerationPool.new(size.times.map { RBS::MultithreadLoader::TypeNameEnumerator.new() })
  type_name_enumeration.each(srcs)

  enums = type_name_enumeration.values

  all_names = Set[]
  aliases = {}

  enums.each do |enum|
    all_names.merge(enum.names)
    aliases.merge!(enum.aliases)
  end

  all_names.freeze
  aliases.freeze

  resolvers = size.times.map { RBS::Resolver::TypeNameResolver.new(all_names, aliases.dup) }
  pairs = resolvers.map {|resolver|
    table = RBS::Environment::UseMap::Table.new()
    table.known_types.merge(all_names)
    table.known_types.merge(aliases.each_key)
    table.compute_children

    [resolver, table]
  }

  resolve_pool = ResolverPool.new(pairs)

  results = []

  results.concat resolve_pool.map(srcs)

  env = RBS::Environment.new
  results.each do |decls|
    decls.each do |decl|
      env.insert_rbs_decl(decl, context: nil, namespace: RBS::Namespace.root)
    end
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
