# frozen_string_literal: true

# This is the file jar-dependencies generates from the `jar` requirements in
# rbs.gemspec, kept with hand edits:
#   1. the `com.dylibso.chicory:runtime` require_jar line is corrected -- the
#      generator mangles that artifact id to `jar` (it collides with a Maven
#      scope keyword), which breaks loading;
#   2. the "# this is a generated file" marker is dropped so jar-dependencies
#      does not regenerate (and re-break) this file at gem install;
#   3. a frozen_string_literal magic comment is added (rubocop).
# `rake wasm:install_jars` downloads the jars into ~/.m2; to refresh the list
# after a version bump, regenerate the file and re-apply these edits.
begin
  require 'jar_dependencies'
rescue LoadError
  require 'com/dylibso/chicory/compiler/1.7.5/compiler-1.7.5.jar'
  require 'com/dylibso/chicory/runtime/1.7.5/runtime-1.7.5.jar'
  require 'com/dylibso/chicory/wasm/1.7.5/wasm-1.7.5.jar'
  require 'org/ow2/asm/asm/9.9.1/asm-9.9.1.jar'
  require 'org/ow2/asm/asm-commons/9.9.1/asm-commons-9.9.1.jar'
  require 'org/ow2/asm/asm-tree/9.9.1/asm-tree-9.9.1.jar'
  require 'org/ow2/asm/asm-util/9.9.1/asm-util-9.9.1.jar'
  require 'org/ow2/asm/asm-analysis/9.9.1/asm-analysis-9.9.1.jar'
  require 'com/dylibso/chicory/wasi/1.7.5/wasi-1.7.5.jar'
  require 'com/dylibso/chicory/log/1.7.5/log-1.7.5.jar'
end

if defined? Jars
  require_jar 'com.dylibso.chicory', 'compiler', '1.7.5'
  require_jar 'com.dylibso.chicory', 'runtime', '1.7.5'
  require_jar 'com.dylibso.chicory', 'wasm', '1.7.5'
  require_jar 'org.ow2.asm', 'asm', '9.9.1'
  require_jar 'org.ow2.asm', 'asm-commons', '9.9.1'
  require_jar 'org.ow2.asm', 'asm-tree', '9.9.1'
  require_jar 'org.ow2.asm', 'asm-util', '9.9.1'
  require_jar 'org.ow2.asm', 'asm-analysis', '9.9.1'
  require_jar 'com.dylibso.chicory', 'wasi', '1.7.5'
  require_jar 'com.dylibso.chicory', 'log', '1.7.5'
end
