require 'mkmf'
$INCFLAGS << " -I$(top_srcdir)" if $extmk
$CFLAGS += " -std=c99 "
create_makefile 'rbs_extension'
