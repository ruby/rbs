# Profile the RBS tests in Instruments.
#
# Based on https://www.jviotti.com/2024/01/29/using-xcode-instruments-for-cpp-cpu-profiling.html
#
# The usual Instruments templates are:
# --template 'Allocations'
# --template 'CPU Profiler'
#
# ...but I made myself a custom template called "Ruby" with these instruments:
# - Allocations
# - Points of Integer
# - os_signpost
# - stdout/stderr
# - Time Profiler
# - Sampler
#
# The "Leaks" instrument doesn't work, and IDK why... some issue with libmalloc.

cd /Users/alex/src/github.com/Shopify/rbs

source /opt/dev/sh/chruby/chruby.sh
chruby 3.3.4

TRACE_FILE="$(mktemp -t trace_XXXXXX).trace"

echo "Will save trace file to $TRACE_FILE"

xcrun xctrace record \
  --template 'Ruby' \
  --no-prompt \
  --output "$TRACE_FILE" \
  --target-stdout - \
  --launch \
  -- \
  /Users/alex/Downloads/ruby \
  -w -Ilib -Itest \
  /Users/alex/.gem/ruby/3.3.0/gems/rake-13.2.1/lib/rake/rake_test_loader.rb \
  "test/rbs/signature_parsing_test.rb" \

# "test/rbs/ancestor_builder_test.rb" \
# "test/rbs/ancestor_graph_test.rb" \
# "test/rbs/annotate/annotations_test.rb" \
# "test/rbs/annotate/rdoc_annotator_test.rb" \
# "test/rbs/annotate/rdoc_source_test.rb" \
# "test/rbs/ast/type_param_test.rb" \
# "test/rbs/ast/visitor_test.rb" \
# "test/rbs/buffer_test.rb" \
# "test/rbs/cli_test.rb" \
# "test/rbs/collection/cleaner_test.rb" \
# "test/rbs/collection/config_test.rb" \
# "test/rbs/collection/installer_test.rb" \
# "test/rbs/collection/sources/git_test.rb" \
# "test/rbs/collection/sources/local_test.rb" \
# "test/rbs/collection/sources/stdlib_test.rb" \
# "test/rbs/definition_builder_test.rb" \
# "test/rbs/diff_test.rb" \
# "test/rbs/environment_loader_test.rb" \
# "test/rbs/environment_test.rb" \
# "test/rbs/environment_walker_test.rb" \
# "test/rbs/errors_test.rb" \
# "test/rbs/factory_test.rb" \
# "test/rbs/file_finder_test.rb" \
# "test/rbs/location_test.rb" \
# "test/rbs/locator_test.rb" \
# "test/rbs/method_builder_test.rb" \
# "test/rbs/method_type_parsing_test.rb" \
# "test/rbs/node_usage_test.rb" \
# "test/rbs/parser_test.rb" \
# "test/rbs/rb_prototype_test.rb" \
# "test/rbs/rbi_prototype_test.rb" \
# "test/rbs/rdoc/rbs_parser_test.rb" \
# "test/rbs/repository_test.rb" \
# "test/rbs/resolver/constant_resolver_test.rb" \
# "test/rbs/resolver/type_name_resolver_test.rb" \
# "test/rbs/runtime_prototype_test.rb" \
# "test/rbs/schema_test.rb" \
# "test/rbs/sorter_test.rb" \
# "test/rbs/subtractor_test.rb" \
# "test/rbs/test/hook_test.rb" \
# "test/rbs/test/runtime_test_test.rb" \
# "test/rbs/test/setup_helper_test.rb" \
# "test/rbs/test/tester_test.rb" \
# "test/rbs/test/type_check_test.rb" \
# "test/rbs/type_alias_dependency_test.rb" \
# "test/rbs/type_alias_regulartiry_test.rb" \
# "test/rbs/type_parsing_test.rb" \
# "test/rbs/types_test.rb" \
# "test/rbs/use_map_test.rb" \
# "test/rbs/variance_calculator_test.rb" \
# "test/rbs/vendorer_test.rb" \
# "test/rbs/writer_test.rb" \
# "test/validator_test.rb"

echo "xtrace exited with code $?"
# 2 => fail
# 0 => success
# 54 => also success?

open "$TRACE_FILE"
