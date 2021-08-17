module RBS
  module Collection

    # This class represent the configration file.
    class Config
      class LockfileGenerator
        attr_reader :config, :lock, :gemfile_lock, :lock_path

        def self.generate(config_path:, gemfile_lock_path:, with_lockfile: true)
          new(config_path: config_path, gemfile_lock_path: gemfile_lock_path, with_lockfile: with_lockfile).generate
        end

        def initialize(config_path:, gemfile_lock_path:, with_lockfile:)
          @config = Config.from_path config_path
          @lock_path = Config.to_lockfile_path(config_path)
          @lock = Config.from_path(lock_path) if lock_path.exist? && with_lockfile
          @gemfile_lock = Bundler::LockfileParser.new(gemfile_lock_path.read)
        end

        def generate
          config.gems.each do |gem|
            assign_gem(gem_name: gem['name'], version: gem['version'])
          end

          gemfile_lock_gems do |spec|
            assign_gem(gem_name: spec.name, version: spec.version)
          end
          remove_ignored_gems!

          config.dump_to(lock_path)
          config
        end

        private def assign_gem(gem_name:, version:)
          locked = lock&.gem(gem_name)
          specified = config.gem(gem_name)

          return if specified&.dig('ignore')
          return if specified&.dig('collection') # skip if the collection is already filled

          if locked
            # If rbs_collection.lock.yaml contain the gem, use it.
            upsert_gem specified, locked
          else
            # Find the gem from gem_collection.
            collection = find_collection(gem_name: gem_name)
            return unless collection

            installed_version = version
            best_version = find_best_version(version: installed_version, versions: collection.versions({ 'name' => gem_name }))
            # @type var new_content: RBS::Collection::Config::gem_entry
            new_content = {
              'name' => gem_name,
              'version' => best_version.to_s,
              'collection' => collection.to_lockfile,
            }
            upsert_gem specified, new_content
          end
        end

        private def upsert_gem(old, new)
          if old
            old.merge! new
          else
            config.add_gem new
          end
        end

        private def remove_ignored_gems!
          config.gems.reject! { |gem| gem['ignore'] }
        end

        private def gemfile_lock_gems(&block)
          gemfile_lock.specs.each do |spec|
            yield spec
          end
        end

        private def find_collection(gem_name:)
          collections = config.collections

          collections.find { |c| c.has?({ 'name' => gem_name, 'revision' => nil } ) }
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
