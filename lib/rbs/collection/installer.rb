module RBS
  module Collection
    class Installer
      attr_reader :lockfile
      attr_reader :stdout

      def initialize(lockfile_path:, stdout: $stdout)
        @lockfile = Config.from_path(lockfile_path)
        @stdout = stdout
      end

      def install_from_lockfile
        install_to = lockfile.repo_path
        lockfile.gems.each do |config_entry|
          collection_for(config_entry).install(dest: install_to, config_entry: config_entry, stdout: stdout)
        end
        stdout.puts "It's done! #{lockfile.gems.size} gems' RBSs now installed."
      end

      private def collection_for(config_entry)
        @collection_for ||= {}
        key = config_entry['collection'] or raise
        @collection_for[key] ||= Collections.from_config_entry(key)
      end
    end
  end
end
