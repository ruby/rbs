# frozen_string_literal: true

module RBS
  module WASM
    # Single source of truth for the Maven coordinates of the jars the JRuby
    # WebAssembly runtime needs. These jars are NOT shipped inside the gem; they
    # are fetched from Maven Central, the canonical source, so that everyone
    # resolves the same version and conflicting copies cannot be loaded at once.
    #
    # Three consumers share these coordinates:
    #
    #   * rbs.gemspec        - turns them into `jar-dependencies` requirements so
    #                          the jars are downloaded when the `-java` gem is
    #                          installed (see RBS::WASM.jar_requirements).
    #   * RBS::WASM::Runtime - `require_jar`s them at load time.
    #   * rake wasm:vendor_jars - downloads them into a gitignored directory for
    #                          running the test suite from source.
    CHICORY_VERSION = "1.7.5"

    # ow2 ASM, the bytecode library Chicory's AOT compiler depends on. Keep in
    # sync with what the pinned Chicory release declares.
    ASM_VERSION = "9.9.1"

    # Jars Chicory needs to load and run the module.
    REQUIRED_JARS = [
      ["com.dylibso.chicory", "wasm", CHICORY_VERSION],
      ["com.dylibso.chicory", "runtime", CHICORY_VERSION],
      ["com.dylibso.chicory", "log", CHICORY_VERSION],
      ["com.dylibso.chicory", "wasi", CHICORY_VERSION],
    ].freeze

    # Jars for Chicory's ahead-of-time compiler (wasm -> JVM bytecode), which
    # runs the parser ~8x faster than the interpreter. Optional: the runtime
    # falls back to the interpreter when they are absent. `compiler` is Chicory's
    # AOT compiler; the asm* jars are the ow2 ASM libraries it depends on.
    OPTIONAL_JARS = [
      ["com.dylibso.chicory", "compiler", CHICORY_VERSION],
      ["org.ow2.asm", "asm", ASM_VERSION],
      ["org.ow2.asm", "asm-tree", ASM_VERSION],
      ["org.ow2.asm", "asm-util", ASM_VERSION],
      ["org.ow2.asm", "asm-commons", ASM_VERSION],
      ["org.ow2.asm", "asm-analysis", ASM_VERSION],
    ].freeze

    # Every jar the runtime can use, in load order.
    ALL_JARS = (REQUIRED_JARS + OPTIONAL_JARS).freeze

    # The `spec.requirements` strings jar-dependencies reads at gem install time
    # to fetch the jars from Maven, e.g. "jar com.dylibso.chicory:runtime, 1.7.5".
    def self.jar_requirements
      ALL_JARS.map { |group, artifact, version| "jar #{group}:#{artifact}, #{version}" }
    end

    # The Maven Central download URL for a [group, artifact, version] coordinate.
    def self.maven_url(group, artifact, version)
      "https://repo1.maven.org/maven2/#{group.tr(".", "/")}/#{artifact}/#{version}/#{artifact}-#{version}.jar"
    end
  end
end
