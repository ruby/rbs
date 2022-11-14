module RBS
  module Collection
    class Config
      class Lockfile
        attr_reader :file_path, :sources, :gems, :path, :gemfile_lock_path

        def initialize(file_path:, path:, gemfile_lock_path:)
          @file_path = file_path
          @path = path
          @gemfile_lock_path = gemfile_lock_path

          @gems = {}
          @sources = []
        end

        def dump
          {
            "sources" => sources.map {|source|
              # @type block: lockfile_source_git_source
              {
                "name" => source.name,
                "remote" => source.remote,
                "revision" => source.resolved_revision,
                "repo_dir" => source.repo_dir
              }
            },
            "path" => path.to_s,
            "gems" => gems.values.sort_by {|gem| gem[:name] }.map {|gem|
              # @type block: lockfile_source_gem
              {
                "name" => gem[:name],
                "version" => gem[:version],
                "source" => gem[:source].to_lockfile
              }
            },
            "gemfile_lock_path" => gemfile_lock_path&.to_s
          }
        end

        def dump_to(io)
          YAML.dump(dump, io)
        end

        def all_sources
          sources + [Sources::Stdlib.instance, Sources::Rubygems.instance]
        end

        def self.load(file_path, yaml)
          path = Pathname(yaml["path"])
          if lock_path = yaml["gemfile_lock_path"]
            gemfile_lock_path = Pathname(lock_path)
          end

          lockfile = Lockfile.new(file_path: file_path, path: path, gemfile_lock_path: gemfile_lock_path)

          Array(yaml['sources']).each do |src|
            lockfile.sources << Sources::Git.new(
              name: src["name"],
              revision: src["revision"],
              remote: src["remote"],
              repo_dir: src["repo_dir"]
            )
          end

          Array(yaml["gems"]).each do |gem|
            source = lockfile.all_sources.find {|source| source.has?(gem['name'], gem['version']) } or raise
            lockfile.gems[gem['name']] = {
              name: gem['name'],
              version: gem['version'],
              source: source
            }
          end

          lockfile
        end
      end
    end
  end
end

