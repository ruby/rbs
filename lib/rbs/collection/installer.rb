module RBS
  module Collection
    class Installer
      attr_reader :lockfile

      METADATA_FILENAME = '.rbs_meta.yaml'

      def initialize(lockfile_path:)
        @lockfile = Config.from_path(lockfile_path)
      end

      def install_from_lockfile
        install_to = lockfile.repo_path
        lockfile.gems.each do |config_entry|
          gem_name = config_entry['name']
          version = config_entry['version']
          gem_dir = install_to.join(gem_name, version)

          if gem_dir.directory?
            if (prev = YAML.load_file(gem_dir.join(METADATA_FILENAME))) == config_entry
              RBS.logger.info "Using #{format_config_entry(config_entry)}"
            else
              # @type var prev: RBS::Collection::Config::gem_entry
              RBS.logger.info "Updating to #{format_config_entry(config_entry)} from #{format_config_entry(prev)}"
              gem_dir.rmtree
              collection_for(config_entry).install(install_to, config_entry)
            end
          else
            RBS.logger.info "Installing #{format_config_entry(config_entry)}"
            collection_for(config_entry).install(install_to, config_entry)
          end
        end
      end

      private def collection_for(config_entry)
        @collection_for ||= {}
        key = config_entry['collection']
        @collection_for[key] ||= Collections.from_config_entry(key)
      end

      # TODO: Support non git collection such as stdlib
      private def format_config_entry(config_entry)
        name = config_entry['name']
        v = config_entry['version']
        rev = config_entry['revision']
        # shorten sha1 commit hash
        rev = rev[0..10] if /\A[a-f0-9]{40}\z/.match? rev

        "#{name}:#{v} (#{rev})"
      end
    end
  end
end
