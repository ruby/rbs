require_relative './collections/git'
require_relative './collections/stdlib'
require_relative './collections/rubygems'

module RBS
  module Collection
    module Collections
      def self.from_config_entry(collection_entry)
        case collection_entry['type']
        when 'git', nil # git collection by default
          Git.new(**(_=collection_entry).slice('name', 'revision', 'remote', 'repo_dir').transform_keys(&:to_sym))
        when 'stdlib'
          Stdlib.instance
        when 'rubygems'
          Rubygems.instance
        else
          raise
        end
      end
    end
  end
end
