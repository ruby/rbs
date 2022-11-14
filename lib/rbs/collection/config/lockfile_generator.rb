# frozen_string_literal: true

module RBS
  module Collection
    class Config
      class LockfileGenerator
        class GemfileLockMismatchError < StandardError
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

        attr_reader :config, :lockfile, :gemfile_lock, :existing_lockfile

        def self.generate(config:, gemfile_lock_path:, with_lockfile: true)
          generator = new(config: config, gemfile_lock_path: gemfile_lock_path, with_lockfile: with_lockfile)
          generator.generate
          generator.lockfile
        end

        def initialize(config:, gemfile_lock_path:, with_lockfile:)
          @config = config

          lockfile_path = Config.to_lockfile_path(config.config_path)
          lockfile_dir = lockfile_path.parent

          @lockfile = Lockfile.new(
            lockfile_path: lockfile_path,
            path: config.repo_path_data,
            gemfile_lock_path: gemfile_lock_path.relative_path_from(lockfile_dir)
          )
          config.sources.each do |source|
            case source
            when Sources::Git
              lockfile.sources[source.name] = source
            end
          end

          if with_lockfile && lockfile_path.file?
            @existing_lockfile = Lockfile.from_lockfile(lockfile_path: lockfile_path, data: YAML.load_file(lockfile_path.to_s))
            validate_gemfile_lock_path!(lock: @existing_lockfile, gemfile_lock_path: gemfile_lock_path)
          end

          @gemfile_lock = Bundler::LockfileParser.new(gemfile_lock_path.read)
        end

        def generate
          ignored_gems = config.gems.select {|gem| gem["ignore"] }.map {|gem| gem["name"] }.to_set

          config.gems.each do |gem|
            if Sources::Stdlib.instance.has?(gem["name"], nil)
              assign_stdlib(name: gem["name"], from_gem: nil) unless ignored_gems.include?(gem["name"])
            else
              assign_gem(name: gem["name"], version: gem["version"], ignored_gems: ignored_gems)
            end
          end

          gemfile_lock_gems do |spec|
            assign_gem(name: spec.name, version: spec.version, ignored_gems: ignored_gems)
          end

          lockfile.lockfile_path.write(YAML.dump(lockfile.to_lockfile))
        end

        private def validate_gemfile_lock_path!(lock:, gemfile_lock_path:)
          return unless lock
          return unless lock.gemfile_lock_fullpath
          unless lock.gemfile_lock_fullpath == gemfile_lock_path
            raise GemfileLockMismatchError.new(expected: lock.gemfile_lock_fullpath, actual: gemfile_lock_path)
          end
        end

        private def assign_gem(name:, version:, ignored_gems:)
          return if ignored_gems.include?(name)
          return if lockfile.gems.key?(name)

          # @type var locked: Lockfile::library?

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

          lockfile.gems[name] = locked
          source = locked[:source]

          source.dependencies_of(locked[:name], locked[:version])&.each do |dep|
            assign_stdlib(name: dep["name"], from_gem: name)
          end
        end

        private def assign_stdlib(name:, from_gem:)
          return if lockfile.gems.key?(name)

          if name == 'rubygems'
            if from_gem
                RBS.logger.warn "`rubygems` has been moved to core library, so it is always loaded. Remove explicit loading `rubygems` from `#{from_gem}`"
            else
              RBS.logger.warn '`rubygems` has been moved to core library, so it is always loaded. Remove explicit loading `rubygems`'
            end

            return
          end

          source = Sources::Stdlib.instance
          lockfile.gems[name] = { name: name, version: "0", source: source }

          unless source.has?(name, nil)
            raise "Cannot find `#{name}` from standard libraries"
          end

          if deps = source.dependencies_of(name, "0")
            deps.each do |dep|
              assign_stdlib(name: dep["name"], from_gem: name)
            end
          end
        end

        private def gemfile_lock_gems(&block)
          gemfile_lock.specs.each do |spec|
            yield spec
          end
        end

        private def find_source(name:)
          sources = config.sources

          sources.find { |c| c.has?(name, nil) }
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
