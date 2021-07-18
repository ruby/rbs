module RBS
  module Collection
    class Cleaner
      attr_reader :lock

      def initialize(lockfile_path:)
        @lock = Config.from_path(lockfile_path)
      end

      def clean
        lock.repo_path.glob('*/*') do |dir|
          *_, gem_name, version = dir.to_s.split('/')
          gem_name = _ = gem_name
          version = _ = version
          next if needed? gem_name, version

          dir.rmtree
        end
      end

      def needed?(gem_name, version)
        gem = lock.gem(gem_name)
        return false unless gem

        gem['version'] == version
      end
    end
  end
end
