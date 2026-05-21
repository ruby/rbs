# frozen_string_literal: true

require "rbs/version"

require "set"
require "json"
require "pathname" unless defined?(Pathname)
require "pp"
require "logger"
require "tsort"
require "strscan"
require "prism"

require "rbs/errors"
require "rbs/buffer"
require "rbs/namespace"
require "rbs/type_name"
require "rbs/types"
require "rbs/method_type"
require "rbs/file_finder"
require "rbs/ast/type_param"
require "rbs/ast/directives"
require "rbs/ast/declarations"
require "rbs/ast/members"
require "rbs/ast/annotation"
require "rbs/ast/visitor"
require "rbs/ast/ruby/comment_block"
require "rbs/ast/ruby/helpers/constant_helper"
require "rbs/ast/ruby/helpers/location_helper"
require "rbs/ast/ruby/annotations"
require "rbs/ast/ruby/declarations"
require "rbs/ast/ruby/members"
require "rbs/source"
require "rbs/inline_parser"
require "rbs/inline_parser/comment_association"
require "rbs/environment"
require "rbs/environment/use_map"
require "rbs/environment/class_entry"
require "rbs/environment/module_entry"
require "rbs/environment_loader"
require "rbs/builtin_names"
require "rbs/definition"
require "rbs/definition_builder"
require "rbs/definition_builder/ancestor_builder"
require "rbs/definition_builder/method_builder"
require "rbs/diff"
require "rbs/variance_calculator"
require "rbs/substitution"
require "rbs/constant"
require "rbs/resolver/constant_resolver"
require "rbs/resolver/type_name_resolver"
require "rbs/ast/comment"
require "rbs/writer"
require "rbs/rewriter"
require "rbs/prototype/helpers"
require "rbs/prototype/rbi"
require "rbs/prototype/rb"
require "rbs/prototype/runtime"
require "rbs/prototype/node_usage"
require "rbs/environment_walker"
require "rbs/vendorer"
require "rbs/validator"
require "rbs/factory"
require "rbs/repository"
require "rbs/subtractor"
require "rbs/ancestor_graph"
require "rbs/locator"
require "rbs/type_alias_dependency"
require "rbs/type_alias_regularity"
require "rbs/collection"

require "rbs_extension"
require "rbs/parser_aux"
require "rbs/location_aux"

module RBS
  class <<self
    attr_reader :logger_level
    attr_reader :logger_output

    def logger
      @logger ||= Logger.new(logger_output || STDERR, level: logger_level || Logger::WARN, progname: "rbs")
    end

    def logger_output=(val)
      @logger = nil
      @logger_output = val
    end

    def logger_level=(level)
      @logger_level = level
      @logger = nil
    end

    def print_warning()
      @warnings ||= Set[]

      message = yield()

      unless @warnings.include?(message)
        @warnings << message
        logger.warn { message }
      end
    end

    # Internal helper for `map_type_name` / `map_type` / `resolve_*` paths
    # in this gem. The given block is invoked for every element. Returns
    # the input array unchanged (the same object) when every mapped result
    # is `equal?` to its source; otherwise returns a fresh array with the
    # changed elements substituted in. Callers detect a no-op by comparing
    # the return value with the input via `equal?`, which avoids
    # allocating a `[mapped, changed]` tuple on every invocation.
    def map_if_changed(array, &)
      return array if array.empty?

      result = array
      changed = false
      array.each_with_index do |element, i|
        new_element = yield(element)
        next if new_element.equal?(element)

        unless changed
          result = array.dup
          changed = true
        end
        result[i] = new_element
      end
      result
    end

    # Hash counterpart of `map_if_changed`: transforms values through the
    # block and returns the receiver unchanged when every value identity
    # is preserved.
    def transform_values_if_changed(hash, &)
      return hash if hash.empty?

      result = hash
      changed = false
      hash.each do |key, value|
        new_value = yield(value)
        next if new_value.equal?(value)

        unless changed
          result = hash.dup
          changed = true
        end
        result[key] = new_value
      end
      result
    end
  end
end
