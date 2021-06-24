module RBS
  module Collection
    class Config
      class GemfileLockLoader
        attr_reader :lock, :gemfile_lock

        def initialize(lock:, gemfile_lock:)
          @lock = lock
          @gemfile_lock = gemfile_lock
        end

        def load(config)
          gemfile_lock.specs.each do |spec|
            locked = lock&.gem(spec.name)
            collection = find_collection(config: config, gem_name: spec.name)
            next unless collection

            specified = config.gem(spec.name)
            next if specified&.dig('ignore')

            if locked
              # TODO: Check the collection equality
              config.add_gem(locked)
            else
              installed_version = spec.version
              best_version = find_best_version(version: installed_version, versions: collection.versions({ 'name' => spec.name }))
              # TODO: make gem entry
              config.add_gem({
                'name' => spec.name,
                'version' => best_version.to_s,
                'collection' => collection.to_h,
              })
            end
          end
        end

        def find_collection(config:, gem_name:)
          gem = config.gem(gem_name)
          locked = lock&.gem(gem_name)
          collections = config.collections

          if gem&.dig('collection')
            c = collections.find { |c| c.name == gem['collection'] }
            return c || raise("#{gem_name} gem needs #{gem['collection']} collection, but it is not defined")
          end

          if locked&.dig('collection')
            c = collections.find { |c| c.name == gem['collection'] }
            return c if c
          end

          collections.find { |c| c.has?({ 'name' => gem_name, 'revision' => nil } ) }
        end

        def find_best_version(version:, versions:)
          v = Gem::Version.create(version) or raise
          candidates = versions.map { |v| Gem::Version.create(v) or raise }
          Repository.find_best_version(v, candidates)
        end
      end
    end
  end
end
