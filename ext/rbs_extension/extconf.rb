require 'mkmf'
$INCFLAGS << " -I$(top_srcdir)" if $extmk
$CFLAGS += " -std=c99 -Wold-style-definition" unless have_macro('_MSC_VER')
create_makefile 'rbs_extension'
