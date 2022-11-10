# frozen_string_literal: true

require 'digest/sha2'
require 'open3'
require 'find'

module RBS
  module Collection
    module Sources
      class Git
        include Base
        METADATA_FILENAME = '.rbs_meta.yaml'

        class CommandError < StandardError; end

        attr_reader :name, :remote, :repo_dir

        def initialize(name:, revision:, remote:, repo_dir:)
          @name = name
          @remote = remote
          @repo_dir = repo_dir || 'gems'

          setup!(revision: revision)
        end

        def has?(name, version)
          if gem_repo_dir.join(name).directory?
            if version
              versions(name).include?(version)
            else
              true
            end
          end
        end

        def versions(name)
          gem_repo_dir.join(name).glob('*/').map { |path| path.basename.to_s }
        end

        def install(dest:, name:, version:, stdout:)
          gem_dir = dest.join(name, version)

          if gem_dir.directory?
            prev = load_metadata(dir: gem_dir)

            if prev == metadata_content(name: name, version: version)
              stdout.puts "Using #{format_config_entry(name, version)}"
            else
              stdout.puts "Updating to #{format_config_entry(name, version)} from #{format_config_entry(prev["name"], prev["version"])}"
              FileUtils.remove_entry_secure(gem_dir.to_s)
              _install(dest: dest, name: name, version: version)
            end
          else
            stdout.puts "Installing #{format_config_entry(name, version)}"
            _install(dest: dest, name: name, version: version)
          end
        end

        def manifest_of(name, version)
          gem_dir = gem_repo_dir.join(name, version)

          manifest_path = gem_dir.join('manifest.yaml')
          if manifest_path.exist?
            Manifest.from(manifest_path, YAML.safe_load(manifest_path.read))
          end
        end

        private def _install(dest:, name:, version:)
          dir = dest.join(name, version)
          dir.mkpath
          src = gem_repo_dir.join(name, version)

          cp_r(src, dir)
          write_metadata(dir: dir, name: name, version: version)
        end

        private def cp_r(src, dest)
          Find.find(src) do |file_src|
            file_src = Pathname(file_src)

            # Skip file if it starts with _, such as _test/
            Find.prune if file_src.basename.to_s.start_with?('_')

            file_src_relative = file_src.relative_path_from(src)
            file_dest = dest.join(file_src_relative)
            file_dest.dirname.mkpath
            FileUtils.copy_entry(file_src, file_dest, false, true) unless file_src.directory?
          end
        end

        def to_lockfile
          {
            'type' => 'git',
            'name' => name,
            'revision' => resolved_revision,
            'remote' => remote,
            'repo_dir' => repo_dir,
          }
        end

        private def format_config_entry(name, version)
          rev = resolved_revision[0..10]
          desc = "#{name}@#{rev}"

          "#{name}:#{version} (#{desc})"
        end

        private def setup!(revision:)
          git_dir.mkpath
          if git_dir.join('.git').directory?
            if need_to_fetch?(revision)
              git 'fetch', 'origin'
            end
          else
            begin
              # git v2.27.0 or greater
              git 'clone', '--filter=blob:none', remote, git_dir.to_s, chdir: nil
            rescue CommandError
              git 'clone', remote, git_dir.to_s, chdir: nil
            end
          end

          begin
            git 'checkout', "origin/#{revision}" # for branch name as `revision`
          rescue CommandError
            git 'checkout', revision
          end
        end

        private def need_to_fetch?(revision)
          return true unless revision.match?(/\A[a-f0-9]{40}\z/)

          begin
            git('cat-file', '-e', revision)
            false
          rescue CommandError
            true
          end
        end

        private def git_dir
          @git_dir ||= (
            base = Pathname(ENV['XDG_CACHE_HOME'] || File.expand_path("~/.cache"))
            cache_key = remote.start_with?('.') ? "#{remote}\0#{Dir.pwd}" : remote
            dir = base.join('rbs', Digest::SHA256.hexdigest(cache_key))
            dir.mkpath
            dir
          )
        end

        private def gem_repo_dir
          git_dir.join @repo_dir
        end

        private def resolved_revision
          @resolved_revision ||= resolve_revision
        end

        private def resolve_revision
          git('rev-parse', 'HEAD').chomp
        end

        private def git(*cmd, **opt)
          sh! 'git', *cmd, **opt
        end

        private def sh!(*cmd, **opt)
          RBS.logger.debug "$ #{cmd.join(' ')}"
          opt = { chdir: git_dir }.merge(opt).compact
          (__skip__ = Open3.capture3(*cmd, **opt)).then do |out, err, status|
            raise CommandError, "Unexpected status #{status.exitstatus}\n\n#{err}" unless status.success?

            out
          end
        end

        def metadata_content(name:, version:)
          {
            "name" => name,
            "version" => version,
            "source" => to_lockfile
          }
        end

        def write_metadata(dir:, name:, version:)
          dir.join(METADATA_FILENAME).write(
            YAML.dump(
              metadata_content(name: name, version: version)
            )
          )
        end

        def load_metadata(dir:)
          # @type var content: Hash[String, untyped]
          content = YAML.load_file(dir.join(METADATA_FILENAME).to_s)
          _ = content.slice("name", "version", "source")
        end
      end
    end
  end
end
