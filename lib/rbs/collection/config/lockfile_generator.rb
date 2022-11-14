# frozen_string_literal: true

module RBS
  module Collection
    class Config
      class LockfileGenerator
        class GemfileLockMismatchError < StandardError
          attr_reader :expected, :actual

          def initialize(expected:, actual:)
            @expected = expected
            @actual = actual
          end

          def message
            <<~MESSAGE
              RBS Collection loads a different Gemfile.lock from before.
              The Gemfile.lock must be the same as that is recorded in rbs_collection.lock.yaml.
              Expected Gemfile.lock: #{@expected}
              Actual Gemfile.lock: #{@actual}
            MESSAGE
          end
        end

        attr_reader :config, :bundler_definition, :lockfile, :existing_lockfile

        def self.generate(config_path:, gemfile_lock_path:, with_lockfile: true)
          gemfile_path = gemfile_lock_path.sub_ext("")
          definition = Bundler::Definition.build(gemfile_path, gemfile_lock_path, {})

          generator = new(config_path: config_path, bundler_definition: definition, with_lockfile: with_lockfile)
          generator.generate

          [
            generator.config,
            generator.lockfile
          ]
        end

        def initialize(config_path:, bundler_definition:, with_lockfile:)
          @config = Config.from_path config_path
          @bundler_definition = bundler_definition

          lock_path = Config.to_lockfile_path(config_path)
          gemfile_lock_path = bundler_definition.lockfile.relative_path_from(lock_path)

          @lockfile = Lockfile.new(file_path: lock_path, path: Pathname(config.data_path), gemfile_lock_path: gemfile_lock_path)
          config.sources.each do |source|
            case source
            when Sources::Git
              lockfile.sources << source
            end
          end

          if with_lockfile && lock_path.file?
            @existing_lockfile = Lockfile.load(lock_path, YAML.load_file(lock_path.to_s))
            validate_gemfile_lock_path!(lock: @existing_lockfile, gemfile_lock_path: gemfile_lock_path)
          end
        end

        def generate
          ignored_gems = config.gems.select {|gem| gem['ignore'] }.map {|gem| gem['name'] }.to_set

          config.gems.each do |gem|
            unless ignored_gems.include?(gem['name'])
              assign_gem(name: gem['name'], version: gem['version'])
            end
          end

          gemfile_lock_gems do |spec|
            unless ignored_gems.include?(spec.name)
              assign_gem(name: spec.name, version: spec.version)
            end
          end

          content = YAML.dump(lockfile.dump)
          lockfile.file_path.write(content)
        end

        private def validate_gemfile_lock_path!(lock:, gemfile_lock_path:)
          return unless lock
          return unless lock.gemfile_lock_path
          return if lock.gemfile_lock_path == gemfile_lock_path

          raise GemfileLockMismatchError.new(expected: lock.gemfile_lock_path, actual: gemfile_lock_path)
        end

        private def assign_gem(name:, version:)
          return if lockfile.gems.key?(name)

          # @type var locked: Lockfile::gem?
          if existing_lockfile
            locked = existing_lockfile.gems[name]
          end

          # If rbs_collection.lock.yaml contain the gem, use it.
          # Else find the gem from gem_collection.
          unless locked
            source = find_source(name: name)
            return unless source

            installed_version = version
            best_version = find_best_version(version: installed_version, versions: source.versions(name))

            locked = {
              name: name,
              version: best_version.to_s,
              source: source,
            }
          end

          locked or raise

          lockfile.gems[locked[:name]] = locked

          source = locked[:source]
          source.dependencies_of(locked[:name], locked[:version])&.each do |dep|
            assign_stdlib(name: dep.name)
          end
        end

        private def assign_stdlib(name:)
          return if lockfile.gems.key?(name)

          source = Sources::Stdlib.instance
          raise "Cannot find stdlib RBS of `#{name}`" unless source.has?(name, nil)

          version = source.versions(name).last || raise
          lockfile.gems[name] = { name: name, version: version, source: source }
          if deps = source.dependencies_of(name, version)
            deps.each do |dep|
              assign_stdlib(name: dep.name)
            end
          end
        end

        private def gemfile_lock_gems(&block)
          bundler_definition.locked_gems.specs.each do |spec|
            yield spec
          end
        end

        private def find_source(name:)
          sources = config.sources
          _ = sources.find { |c| c.has?(name, nil) }
        end

        private def find_best_version(version:, versions:)
          candidates = versions.map { |v| Gem::Version.create(v) or raise }
          return candidates.max || raise unless version

          v = Gem::Version.create(version) or raise
          Repository.find_best_version(v, candidates)
        end
      end
    end
  end
end
