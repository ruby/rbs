D = Steep::Diagnostic

libs = [
  "set", "pathname", "json", "logger", "monitor",
  "tsort", "uri", 'dbm', 'pstore', 'singleton',
  'shellwords', 'fileutils', 'find', 'digest', 'abbrev',
]

libs_from_local_path = [
  'stdlib/yaml/0',
  "stdlib/strscan/0/",
  "stdlib/optparse/0/",
  "stdlib/rdoc/0/",
  "stdlib/ripper/0",
]

target :lib do
  signature "sig"
  check "lib"
  ignore(
    "lib/rbs/prototype/runtime.rb",
    "lib/rbs/test",
    "lib/rbs/test.rb"
  )

  library(*libs)
  libs_from_local_path.each do |path|
    signature path
  end

  configure_code_diagnostics do |config|
    config[D::Ruby::MethodDefinitionMissing] = :hint
    config[D::Ruby::ElseOnExhaustiveCase] = :hint
    config[D::Ruby::FallbackAny] = :hint
  end
end

target :test do
  signature 'sig'
  check 'test'

  # Ignore the following file because Steep causes SystemStackError on this file.
  ignore "test/stdlib/enumerator/Product_test.rb"

  library(*libs)
  libs_from_local_path.each do |path|
    signature path
  end

  configure_code_diagnostics(D::Ruby.all_error.transform_values { nil })
end

# target :lib do
#   signature "sig"
#
#   check "lib"                       # Directory name
#   check "Gemfile"                   # File name
#   check "app/models/**/*.rb"        # Glob
#   # ignore "lib/templates/*.rb"
#
#   # library "pathname", "set"       # Standard libraries
#   # library "strong_json"           # Gems
# end

# target :spec do
#   signature "sig", "sig-private"
#
#   check "spec"
#
#   # library "pathname", "set"       # Standard libraries
#   # library "rspec"
# end
