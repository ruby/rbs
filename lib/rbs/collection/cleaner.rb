module RBS
  module Collection
    class Cleaner
      attr_reader :lock

      def initialize(lock:)
        @lock = lock
      end

      def clean
        lock.path.glob('*/*') do |dir|
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
