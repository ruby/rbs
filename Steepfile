D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"
  ignore(
    "lib/rbs/test",
    # "lib/rbs/test.rb"
  )

  library "pathname", "json", "logger", "monitor", "tsort", "uri", 'dbm', 'pstore', 'singleton', 'shellwords', 'fileutils', 'find', 'digest', 'abbrev', 'prettyprint', 'yaml', "psych", "securerandom"
  signature "stdlib/strscan/0/"
  signature "stdlib/optparse/0/"
  signature "stdlib/rdoc/0/"
  signature "stdlib/ripper/0"
  signature "stdlib/pp/0"

  # configure_code_diagnostics do |config|
  #   config[D::Ruby::MethodDefinitionMissing] = :hint
  #   config[D::Ruby::ElseOnExhaustiveCase] = :hint
  #   config[D::Ruby::FallbackAny] = :hint
  # end
end

# target :lib do
#   signature "sig"
#
#   check "lib"                       # Directory name
#   check "Gemfile"                   # File name
#   check "app/models/**/*.rb"        # Glob
#   # ignore "lib/templates/*.rb"
#
#   # library "pathname", "uri"       # Standard libraries
#   # library "strong_json"           # Gems
# end

# target :spec do
#   signature "sig", "sig-private"
#
#   check "spec"
#
#   # library "pathname", "uri"       # Standard libraries
#   # library "rspec"
# end
