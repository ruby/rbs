require 'mkmf'

$INCFLAGS << " -I$(top_srcdir)" if $extmk
$INCFLAGS << " -I$(srcdir)/../../include"

$VPATH << "$(srcdir)/../../src"
$VPATH << "$(srcdir)/../../src/util"
$VPATH << "$(srcdir)/ext/rbs_extension"

root_dir = File.expand_path('../../../', __FILE__)
$srcs = Dir.glob("#{root_dir}/src/**/*.c") +
        Dir.glob("#{root_dir}/ext/rbs_extension/*.c")

append_cflags ['-std=gnu99', '-Wimplicit-fallthrough', '-Wunused-result']
append_cflags ['-O0', '-g'] if ENV['DEBUG']
if ENV["TEST_NO_C23"]
  puts "Adding -Wc2x-extensions to CFLAGS"
  $CFLAGS << " -Werror -Wc2x-extensions"
end

create_makefile 'rbs_extension'
