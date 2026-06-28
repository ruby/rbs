# frozen_string_literal: true
#
# Loads the Chicory/ASM jars for the JRuby WebAssembly parser (RBS::WASM::Runtime)
# from the local Maven repository. Hand-maintained, NOT auto-generated: the
# jar-dependencies generator mangles the `com.dylibso.chicory:runtime` artifact id
# into `jar` (its artifact name collides with a Maven scope keyword). Leaving out
# the usual "this is a generated file" marker also stops jar-dependencies from
# overwriting this file at gem install. Keep this list in sync with the `jar`
# requirements in rbs.gemspec.
require "jar_dependencies"

require_jar "com.dylibso.chicory", "wasm", "1.7.5"
require_jar "com.dylibso.chicory", "runtime", "1.7.5"
require_jar "com.dylibso.chicory", "log", "1.7.5"
require_jar "com.dylibso.chicory", "wasi", "1.7.5"
require_jar "com.dylibso.chicory", "compiler", "1.7.5"
require_jar "org.ow2.asm", "asm", "9.9.1"
require_jar "org.ow2.asm", "asm-tree", "9.9.1"
require_jar "org.ow2.asm", "asm-util", "9.9.1"
require_jar "org.ow2.asm", "asm-commons", "9.9.1"
require_jar "org.ow2.asm", "asm-analysis", "9.9.1"
