# frozen_string_literal: true

module RBS
  module Collection
    module Sources
      module Base
        def dependencies_of(name, version)
          manifest = manifest_of(name, version) or return
          manifest['dependencies']
        end

        def switch_io(stdout)
          orig_stdout = $stdout
          $stdout = stdout
          yield
        ensure
          $stdout = orig_stdout
        end
      end
    end
  end
end
