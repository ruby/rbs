# frozen_string_literal: true

begin
  gem 'rdoc', '>= 6.16'
  require 'rdoc_plugin/parser'
  # Guard against defining the parser twice. When two copies of rbs are on the
  # load path (e.g. an installed gem and a source checkout, as in `ruby/ruby`'s
  # `test-bundled-gems`), RDoc's plugin discovery requires each `rdoc/discover.rb`,
  # which would otherwise redefine `RDoc::Parser::RBS#scan` and emit a
  # "method redefined" warning.
  unless RDoc::Parser.const_defined?(:RBS, false)
    module RDoc
      class Parser
        class RBS < Parser
          parse_files_matching(/\.rbs$/)
          def scan
            ::RBS::RDocPlugin::Parser.new(@top_level, @content).scan
          end
        end
      end
    end
  end
rescue Gem::LoadError
    # Error :sad:
rescue Exception
    # Exception :sad:
end
