module RBS
  module Collection
    class Config
      class Lockfile
        attr_reader :lockfile_path, :lockfile_dir, :path, :gemfile_lock_path, :sources, :gems

        def initialize(lockfile_path:, path:, gemfile_lock_path:)
          @lockfile_path = lockfile_path
          @lockfile_dir = lockfile_path.parent
          @path = path
          @gemfile_lock_path = gemfile_lock_path

          @sources = {}
          @gems = {}
        end

        def fullpath
          lockfile_dir + path
        end

        def gemfile_lock_fullpath
          if gemfile_lock_path
            lockfile_dir + gemfile_lock_path
          end
        end

        def each_source(&block)
          if block
            sources.each_value(&block)
            yield Sources::Rubygems.instance
            yield Sources::Stdlib.instance
          else
            enum_for :each_source
          end
        end

        def to_lockfile
          # @type var data: lockfile_data

          data = {
            "sources" => sources.each_value.sort_by {|s| s.name }.map do |source|
              # @type block: git_source_data
              {
                "name" => source.name,
                "remote" => source.remote,
                "revision" => source.resolved_revision,
                "repo_dir" => source.repo_dir
              }
            end,
            "path" => path.to_s,
            "gems" => gems.each_value.sort_by {|g| g[:name] }.map {|hash| library_data(hash) },
            "gemfile_lock_path" => gemfile_lock_path.to_s
          }

          data.delete("sources") if sources.empty?
          data.delete("gems") if gems.empty?

          data
        end

        def self.from_lockfile(lockfile_path:, data:)
          path = Pathname(data["path"])
          if p = data["gemfile_lock_path"]
            gemfile_lock_path = Pathname(p)
          end

          lockfile = Lockfile.new(lockfile_path: lockfile_path, path: path, gemfile_lock_path: gemfile_lock_path)

          if sources = data["sources"]
            sources.each do |src|
              git = Sources::Git.new(
                name: src["name"],
                revision: src["revision"],
                remote: src["remote"],
                repo_dir: src["repo_dir"]
              )
              lockfile.sources[git.name] = git
            end
          end

          if gems = data["gems"]
            gems.each do |gem|
              src = gem["source"]
              source = Sources.from_config_entry(src)
              lockfile.gems[gem["name"]] = {
                name: gem["name"],
                version: gem["version"],
                source: source
              }
            end
          end

          lockfile
        end

        def library_data(lib)
          {
            "name" => lib[:name],
            "version" => lib[:version],
            "source" => lib[:source].to_lockfile
          }
        end

        def check_rbs_availability!
          raise CollectionNotAvailable unless fullpath.exist?

          gems.each_value do |gem|
            source = gem[:source]

            case source
            when Sources::Git
              meta_path = fullpath.join(gem[:name], gem[:version], Sources::Git::METADATA_FILENAME)
              raise CollectionNotAvailable unless meta_path.exist?
              raise CollectionNotAvailable unless library_data(gem) == YAML.load(meta_path.read)
            end
          end
        end
      end
    end
  end
end
