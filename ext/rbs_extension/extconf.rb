if RUBY_ENGINE == "ruby" && ENV["RBS_FFI_BACKEND"].to_s.empty?
  require 'mkmf'

  $INCFLAGS << " -I$(top_srcdir)" if $extmk
  $INCFLAGS << " -I$(srcdir)/../../include"

  $VPATH << "$(srcdir)/../../src"
  $VPATH << "$(srcdir)/../../src/util"
  $VPATH << "$(srcdir)/ext/rbs_extension"

  root_dir = File.expand_path('../../../', __FILE__)
  $srcs = Dir.glob("#{root_dir}/src/**/*.c") +
          Dir.glob("#{root_dir}/ext/rbs_extension/*.c")

  append_cflags [
    '-std=gnu99',
    '-Wimplicit-fallthrough',
    '-Wunused-result',
    '-Wc++-compat',
    '-Wnullable-to-nonnull-conversion',
  ]

  if ENV['DEBUG']
    append_cflags ['-O0', '-pg']
  else
    append_cflags ['-DNDEBUG']
  end
  if ENV["TEST_NO_C23"]
    puts "Adding -Wc2x-extensions to CFLAGS"
    $CFLAGS << " -Werror -Wc2x-extensions"
  end

  create_makefile 'rbs_extension'

  # Only generate compile_commands.json when compiling through Rake tasks
  # This is to avoid adding extconf_compile_commands_json as a runtime dependency
  if ENV["COMPILE_COMMANDS_JSON"]
    require 'extconf_compile_commands_json'
    ExtconfCompileCommandsJson.generate!
    ExtconfCompileCommandsJson.symlink!
  end
else
  # Non-MRI implementations (JRuby, TruffleRuby) cannot load MRI C extensions.
  # Instead, build the Ruby-independent core parser (src/ only, no
  # ext/rbs_extension/ sources) as a plain shared library, loaded at runtime
  # through the ffi gem by lib/rbs/parser/ffi.rb.
  #
  # Setting RBS_FFI_BACKEND=1 forces this path on MRI, which is how the FFI
  # backend is developed and tested without a JRuby installation.
  require 'rbconfig'

  root_dir = File.expand_path('../../../', __FILE__)

  soext = RbConfig::CONFIG["SOEXT"] ||
          (RbConfig::CONFIG["host_os"] =~ /darwin/ ? "dylib" : "so")
  cc = RbConfig::CONFIG["CC"] || ENV["CC"] || "cc"
  output = File.join(root_dir, "lib", "rbs", "librbs.#{soext}")

  sources = Dir.glob("#{root_dir}/src/**/*.c")

  command = [
    cc,
    "-O2",
    "-fPIC",
    "-std=gnu99",
    "-fvisibility=default",
    "-DNDEBUG",
    "-I#{root_dir}/include",
    "-shared",
    "-o", output,
    *sources,
  ]

  puts "Building librbs for the FFI backend: #{output}"
  puts command.join(" ")
  system(*command) or raise "Failed to build librbs with: #{command.join(" ")}"

  # RubyGems expects extconf.rb to produce a Makefile; librbs is already
  # built at this point, so all targets are no-ops.
  File.write("Makefile", <<~MAKEFILE)
    all:
    \t@true
    install:
    \t@true
    clean:
    \t@true
  MAKEFILE
end
