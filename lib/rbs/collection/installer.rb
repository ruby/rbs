module RBS
  module Collection
    class Installer
      attr_reader :lockfile

      def initialize(lockfile_path:)
        @lockfile = Config.from_path(lockfile_path)
      end

      def install_from_lockfile
        install_to = lockfile.path
        lockfile.gems.each do |config_entry|
          RBS.logger.info "Installing #{config_entry['name']}"
          # TODO: more log
          collection_for(config_entry).install(install_to, config_entry)
        end
      end

      private def collection_for(config_entry)
        @collection_for ||= {}
        key = config_entry['collection']
        @collection_for[key] ||= Collections.from_config_entry(key)
      end
    end
  end
end
