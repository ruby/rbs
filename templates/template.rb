# frozen_string_literal: true

require "erb"
require "fileutils"
require "yaml"

module RBS
  class Template
    module StringUtils
      def camel_to_snake(str)
        str.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end
    end

    class Type
      attr_reader :name #: String
      
      attr_reader :c_name #: String
      
      def initialize(name:, c_name:)
        @name = name
        @c_name = c_name
      end
      
      def c_type_name
        c_name
      end
    end

    # A `rbs_node_t` type
    #
    class NodeType < Type
      attr_reader :ruby_name #: String?
      
      def initialize(name:, c_name:, ruby_name:)
        super(name: name, c_name: c_name)
        @ruby_name = ruby_name
      end
      
      def c_type_name
        "#{c_name}_t *"
      end
    end

    class EnumType < Type
      attr_reader :descr #: SymbolEnumDescription
      
      def initialize(descr)
        super(name: descr.name, c_name: descr.c_name)
        @descr = descr
      end

      def c_type_name
        descr.c_type_name
      end
    end

    BUILTIN_TYPES = {
      "VALUE" => Type.new(name: "VALUE", c_name: "VALUE"),
      "bool" => Type.new(name: "bool", c_name: "bool"),
      "rbs_string" => Type.new(name: "rbs_string", c_name: "rbs_string_t"),
      "rbs_node_list" => NodeType.new(name: "rbs_node_list", c_name: "rbs_node_list", ruby_name: nil),
      "rbs_node" => NodeType.new(name: "rbs_node", c_name: "rbs_node", ruby_name: nil),
      "rbs_ast_symbol" => NodeType.new(name: "rbs_ast_symbol", c_name: "rbs_ast_symbol", ruby_name: nil),
      "rbs_hash" => NodeType.new(name: "rbs_hash", c_name: "rbs_hash", ruby_name: nil),
      "rbs_location_range" => Type.new(name: "rbs_location_range", c_name: "rbs_location_range"),
      "rbs_location_range_list" => Type.new(name: "rbs_location_range_list", c_name: "rbs_location_range_list_t *"),
    }

    class Field
      attr_reader :name, :type, :c_name #: String

      def initialize(name:, type:, optional:, c_name: nil)
        @name = name
        @type = type
        @c_name = c_name || name
        @optional = optional
      end

      def self.from_hash(hash)
        new(
          name: hash["name"],
          type: hash.fetch("c_type", "VALUE"),
          c_name: hash["c_name"],
          optional: hash.fetch("optional", false)
        )
      end

      def optional? #: bool
        @optional
      end

      def required? #: bool
        !@optional
      end

      def field_decl
        "#{type.c_type_name} #{c_name}"
      end
    end

    class LocationField
      attr_reader :name #: String

      def initialize(name:, required:)
        @name = name
        @required = required
      end

      # @rbs (Hash[untyped, untyped]) -> RBS::Template::LocationField
      def self.from_hash(hash)
        name = hash["required"] || hash["optional"]
        required = hash.key?("required")
        new(name: name, required: required)
      end

      def required? #: bool
        @required
      end

      def optional? #: bool
        !@required
      end

      def attribute_name #: String
        "#{@name}_range"
      end

      def type_name #: String
        "rbs_location_range"
      end
    end

    FunctionParam = Data.define(:type, :name) do
      def to_s
        "#{type.c_type_name} #{name}"
      end
    end

    # - name: Abstract node type name (RBS::AST::Declarations::TypeAlias)
    # - ruby_full_name: Full name of the Ruby class (RBS::AST::Declarations::TypeAlias)
    # - ruby_base_name: Base name of the Ruby class (TypeAlias)
    # - c_name: name of the C struct (rbs_ast_declarations_type_alias)
    # - rust_name: name of the Rust struct (TypeAliasNode)
    class NodeDescription < Data.define(:name, :ruby_full_name, :c_name, :rust_name, :expose_to_ruby, :expose_location)
      include StringUtils

      def ruby_base_name
        ruby_full_name[/[^:]+\z/] # demodulize-like
      end

      def ruby_parent_name
        ruby_full_name.split("::")[0..-2].join("::")
      end

      def c_name
        super || ruby_full_name.split("::").map { |part| camel_to_snake(part) }.join("_")
      end

      def c_constant_name
        ruby_full_name.gsub("::", "_")
      end

      def c_parent_constant_name
        ruby_parent_name.gsub("::", "_")
      end

      def c_node_enum_name
        c_name.upcase
      end
    end

    class Node
      attr_reader :descr #: NodeDescription
      attr_reader :constructor_params #: Array[RBS::Template::Field]
      attr_reader :fields #: Array[RBS::Template::Field]
      attr_reader :locations #: Array[RBS::Template::LocationField]?

      def initialize(descr, fields, locations, constructor_params)
        @descr = descr
        @fields = fields
        @locations = locations
        @constructor_params = constructor_params
      end

      # The name of the C function which constructs new instances of this C structure.
      # e.g. `rbs_ast_declarations_type_alias_new`
      def c_constructor_function_name #: String
        "#{descr.c_name}_new"
      end

      def c_type_name #: String
        "#{descr.c_name}_t"
      end

      # Every templated type will have a C struct created for it.
      # If this is true, then we will also create a Ruby class for it, otherwise we'll skip that.
      def expose_to_ruby?
        descr.expose_to_ruby
      end

      def expose_location?
        descr.expose_location
      end

      def c_node_enum_name #: String
        descr.c_node_enum_name
      end

      def ruby_full_name #: String
        descr.ruby_full_name
      end

      def c_constant_name #: String
        descr.c_constant_name
      end

      def c_parent_constant_name #: String
        descr.c_parent_constant_name
      end

      def ruby_base_name #: String
        descr.ruby_base_name
      end

      def c_name #: String
        descr.c_name
      end
    end

    class SymbolEnumDescription < Data.define(:name, :symbols, :optional)
      def optional?
        optional
      end

      def required?
        !optional
      end

      def c_type_name
        "enum rbs_#{name}"
      end

      def c_name
        "rbs_#{name}"
      end

      # Yields the symbol name in String, the `enum` constant name in C, and the Ruby value.
      #
      def each_symbol
        symbols.each_with_index do |sym, index|
          constant_name = "RBS_#{name.upcase}_#{sym.to_s.upcase}"
          value =
            unless optional? && index == 0
              sym.to_sym
            end
          yield sym, constant_name, value
        end
      end

      def translator_name
        "rbs_#{name}_to_ruby"
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

        node_desc = config.fetch("nodes").map do |node|
          desc = NodeDescription.new(
            name: node["name"],
            ruby_full_name: node.fetch("name"),
            c_name: node.fetch("c_name", nil),
            rust_name: node.fetch("rust_name", nil),
            expose_to_ruby: node.fetch("expose_to_ruby", true),
            expose_location: node.fetch("expose_location", true),
          )

          [desc, node.fetch("fields", []), node.fetch("locations", nil)]
        end

        types = {}
        types.merge!(BUILTIN_TYPES)

        enum_desc = []
        config.fetch("enums", {}).each do |enum_name, enum_info|
          next unless  enum_info.key?("symbols")
          
          descr = SymbolEnumDescription.new(
            name: enum_name,
            symbols: enum_info.fetch("symbols"),
            optional: enum_info.fetch("optional", false),
          )

          enum_desc << descr
          types[enum_name] = EnumType.new(descr)
        end

        node_desc.each do |node, _, _|
          type = NodeType.new(name: node.name, c_name: node.c_name, ruby_name: node.ruby_full_name)
          types[type.c_name] = type
        end

        nodes = node_desc.map do |node, field_decls, location_decls|
          fields = field_decls.map do |field|
            type = types.fetch(field.fetch("c_type"))
            Field.new(
              name: field.fetch("name"),
              type: type,
              optional: field.fetch("optional", false),
              c_name: field["c_name"],
            )
          end

          locations = location_decls&.map do |loc|
            LocationField.from_hash(loc)
          end

          constructor_params = [
            FunctionParam.new(Type.new(name: "allocator", c_name: "rbs_allocator_t *"), "allocator"),
            FunctionParam.new(types.fetch("rbs_location_range"), "location"),
            *fields.map { FunctionParam.new(_1.type, _1.c_name) },
            *locations&.select(&:required?)&.map { FunctionParam.new(types.fetch("rbs_location_range"), _1.attribute_name) },
          ]

          Node.new(node, fields, locations, constructor_params)
        end

        {
          nodes: nodes.sort_by { _1.descr.ruby_full_name },
          enums: enum_desc
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
