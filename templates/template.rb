# frozen_string_literal: true

require "erb"
require "fileutils"
require "yaml"

module RBS
  class Template
    class Field
      attr_reader :name, :c_type, :c_name #: String

      def initialize(name:, c_type:, c_name: nil)
        @name = name
        @c_type = c_type
        @c_name = c_name || name
      end

      def self.from_hash(hash)
        new(name: hash["name"], c_type: hash.fetch("c_type", "VALUE"), c_name: hash["c_name"])
      end

      def parameter_decl
        case @c_type
        when "VALUE", "bool"
          "#{@c_type} #{c_name}"
        when "rbs_string"
          "rbs_string_t #{c_name}"
        when ->(c_type) { c_type.end_with?("_t *") }
          "#{@c_type}#{c_name}"
        else
          "#{@c_type}_t *#{c_name}"
        end
      end

      def stored_field_decl
        case @c_type
        when "VALUE"
          "VALUE #{c_name}"
        when "bool"
          "bool #{c_name}"
        when "rbs_string"
          "rbs_string_t #{c_name}"
        else
          "struct #{@c_type} *#{c_name}"
        end
      end

      def ast_node?
        @c_type == "rbs_node" ||
          @c_type == "rbs_typename" ||
          @c_type == "rbs_namespace" ||
          @c_type.include?("_ast_") ||
          @c_type.include?("_decl_") ||
          @c_type.include?("_types_")
      end

      # Returns a C expression that evaluates to the Ruby VALUE object for this field.
      def cached_ruby_value_expr
        case @c_type
        when "VALUE"
          @name
        when "bool"
          "#{@name} ? Qtrue : Qfalse"
        when "rbs_node", "rbs_node_list", "rbs_location", "rbs_hash"
          "#{@name} == NULL ? Qnil : #{@name}->cached_ruby_value"
        else
          "#{@name} == NULL ? Qnil : #{@name}->base.cached_ruby_value"
        end
      end

      def needs_to_be_freed?
        !["VALUE", "bool"].include?(@c_type)
      end

      def ast_node?
        @c_type == "rbs_node" ||
          @c_type == "rbs_typename" ||
          @c_type == "rbs_namespace" ||
          @c_type.include?("_ast_") ||
          @c_type.include?("_decl_") ||
          @c_type.include?("_types_")
      end
    end

    class Type
      # The fully-qualified name of the auto-generated Ruby class for this type,
      # e.g. `RBS::AST::Declarations::TypeAlias`
      attr_reader :ruby_full_name #: String

      # The name of the name of the auto-generated Ruby class for this type,
      # e.g. `TypeAlias`
      attr_reader :ruby_class_name #: String

      # The base name of the auto-generated C struct for this type.
      # e.g. `rbs_ast_declarations_typealias`
      attr_reader :c_base_name #: String

      # The name of the typedef of the auto-generated C struct for this type,
      # e.g. `rbs_ast_declarations_typealias_t`
      attr_reader :c_type_name #: String

      # The name of the pre-existing C function which constructs new Ruby objects of this type.
      # e.g. `rbs_ast_declarations_typealias_new`
      attr_reader :c_function_name #: String

      # The name of the C constant which stores the Ruby VALUE pointing to the generated class.
      # e.g. `RBS_AST_Declarations_TypeAlias`
      attr_reader :c_constant_name #: String

      # The name of the C constant in which the `c_constant_name` is nested.
      # e.g. `RBS_AST_Declarations`
      attr_reader :c_parent_constant_name #: String

      attr_reader :c_struct_name #: String
      attr_reader :c_type_enum_name #: String

      attr_reader :constructor_params #: Array[RBS::Template::Field]
      attr_reader :fields #: Array[RBS::Template::Field]

      def initialize(yaml)
        @ruby_full_name = yaml["name"]
        @ruby_class_name = @ruby_full_name[/[^:]+\z/] # demodulize-like
        name = @ruby_full_name.gsub("::", "_")
        @c_function_name = name.gsub(/(^)?(_)?([A-Z](?:[A-Z]*(?=[A-Z_])|[a-z0-9]*))/) { ($1 || $2 || "_") + $3.downcase } # underscore-like
        @c_function_name.gsub!(/^rbs_types_/, 'rbs_')
        @c_function_name.gsub!(/^rbs_ast_declarations_/, 'rbs_ast_decl_')
        @c_constant_name = @ruby_full_name.gsub("::", "_")
        @c_parent_constant_name = @ruby_full_name.split("::")[0..-2].join("::").gsub("::", "_")
        @c_base_name = @c_constant_name.downcase
        @c_type_name = @c_base_name + "_t"

        @c_struct_name = "#{@c_base_name}_t"
        @c_type_enum_name = @c_base_name.upcase

        @expose_to_ruby = yaml.fetch("expose_to_ruby", true)
        @builds_ruby_object_internally = yaml.fetch("builds_ruby_object_internally", true)

        @fields = yaml.fetch("fields", []).map { |field| Field.from_hash(field) }.freeze

        @constructor_params = [Field.new(name: "allocator",  c_type: "rbs_allocator_t *")]
        @constructor_params << Field.new(name: "ruby_value", c_type: "VALUE") unless builds_ruby_object_internally?
        @constructor_params.concat @fields
        @constructor_params.freeze
      end

      # The name of the C function which constructs new instances of this C structure.
      # e.g. `rbs_ast_declarations_typealias_new`
      def c_constructor_function_name #: String
        "#{@c_base_name}_new"
      end

      # Every templated type will have a C struct created for it.
      # If this is true, then we will also create a Ruby class for it, otherwise we'll skip that.
      def expose_to_ruby?
        @expose_to_ruby
      end

      # When true, this object is expected to build its own Ruby VALUE object inside its `*_new()` function.
      # When false, the `*_new()` function will take a Ruby VALUE as its first argument.
      def builds_ruby_object_internally?
        @builds_ruby_object_internally
      end
    end

    class << self
      def render(out_file)
        filepath = "templates/#{out_file}.erb"
        template = File.expand_path("../#{filepath}", __dir__)

        erb = read_template(template)
        extension = File.extname(filepath.gsub(".erb", ""))

        heading = <<~HEADING
          /*----------------------------------------------------------------------------*/
          /* This file is generated by the templates/template.rb script and should not  */
          /* be modified manually.                                                      */
          /* To change the template see                                                 */
          /* #{filepath + " " * (74 - filepath.size) } */
          /*----------------------------------------------------------------------------*/
        HEADING

        write_to = File.expand_path("../#{out_file}", __dir__)
        contents = heading + "\n" + erb.result_with_hash(locals)

        if (extension == ".c" || extension == ".h") && !contents.ascii_only?
          # Enforce that we only have ASCII characters here. This is necessary
          # for non-UTF-8 locales that only allow ASCII characters in C source
          # files.
          contents.each_line.with_index(1) do |line, line_number|
            raise "Non-ASCII character on line #{line_number} of #{write_to}" unless line.ascii_only?
          end
        end

        FileUtils.mkdir_p(File.dirname(write_to))
        File.write(write_to, contents)
      end

      private

      def read_template(filepath)
        template = File.read(filepath, encoding: Encoding::UTF_8)
        erb = erb(template)
        erb.filename = filepath
        erb
      end

      def erb(template)
        ERB.new(template, trim_mode: "-")
      end

      def locals
        config = YAML.load_file(File.expand_path("../config.yml", __dir__))
        {
          nodes: config.fetch("nodes").map { |node| Type.new(node) }.sort_by(&:ruby_full_name),
        }
      end
    end
  end
end

unless ARGV.size == 1
  $stderr.puts "Usage: ruby template.rb <out_file>"
  exit 1
end

out_file = ARGV.first
RBS::Template.render(out_file)
