
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbs/version"

Gem::Specification.new do |spec|
  spec.name          = "rbs"
  spec.version       = RBS::VERSION
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = %q{Type signature for Ruby.}
  spec.description   = %q{RBS is the language for type signatures for Ruby and standard library definitions.}
  spec.homepage      = "https://github.com/ruby/rbs"
  spec.licenses      = ['BSD-2-Clause', 'Ruby']

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/ruby/rbs.git"
    spec.metadata["changelog_uri"] = "https://github.com/ruby/rbs/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      [
        %r{^(test|spec|features|bin|steep|benchmark|templates|rust|\.vscode)/},
        /Gemfile/,
      ].any? {|r| f.match(r) }
    end
  end

  # JRuby cannot load the MRI C extension. On JRuby (and in the `java` platform
  # gem, built with RBS_PLATFORM=java) RBS runs the WebAssembly-backed parser, so
  # ship the prebuilt parser (built by `rake wasm:build`) and skip the C
  # extension. The Chicory/ASM jars the runtime needs are NOT shipped in the gem:
  # they are declared as `jar-dependencies` requirements below and fetched from
  # Maven Central at install time (see lib/rbs/wasm/jars.rb).
  building_java_gem = ENV["RBS_PLATFORM"] == "java"
  on_jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"

  if building_java_gem || on_jruby
    # Only stamp the platform when building the release gem; leave it unset for
    # local development on JRuby so it still matches a `ruby` platform lockfile.
    spec.platform = "java" if building_java_gem
    # rbs_parser.wasm is a build artifact (not tracked in git), so add it
    # explicitly. lib/rbs_jars.rb is committed, so git ls-files already has it.
    spec.files += Dir.chdir(File.expand_path('..', __FILE__)) do
      Dir.glob("lib/rbs/wasm/rbs_parser.wasm")
    end

    # jar-dependencies (bundled with JRuby) downloads these jars from Maven when
    # the gem is installed, keeping the gem small and avoiding conflicting copies.
    # lib/rbs_jars.rb require_jars them at runtime; keep the two lists in sync.
    spec.add_dependency "jar-dependencies", ">= 0.1.7"
    spec.requirements << "jar com.dylibso.chicory:wasm, 1.7.5"
    spec.requirements << "jar com.dylibso.chicory:runtime, 1.7.5"
    spec.requirements << "jar com.dylibso.chicory:log, 1.7.5"
    spec.requirements << "jar com.dylibso.chicory:wasi, 1.7.5"
    spec.requirements << "jar com.dylibso.chicory:compiler, 1.7.5"
    spec.requirements << "jar org.ow2.asm:asm, 9.9.1"
    spec.requirements << "jar org.ow2.asm:asm-tree, 9.9.1"
    spec.requirements << "jar org.ow2.asm:asm-util, 9.9.1"
    spec.requirements << "jar org.ow2.asm:asm-commons, 9.9.1"
    spec.requirements << "jar org.ow2.asm:asm-analysis, 9.9.1"
  else
    spec.extensions = %w{ext/rbs_extension/extconf.rb}
  end

  if false
    spec.required_ruby_version = ">= 3.4"
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.2"
  spec.add_dependency "logger"
  spec.add_dependency "prism", ">= 1.6.0"
  spec.add_dependency "tsort"
end
