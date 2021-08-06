require "json"
require "rbs/json_schema/validation_error"

module RBS
  module JSONSchema
    class Generator
      attr_reader :options
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :name
      attr_reader :decls

      # SCHEMA DEFINITIONS required for generating RBS from JSON schema
      SCHEMA_DEFINITIONS = %w(definitions properties type enum const allOf oneOf items $ref $schema title description).freeze

      # REGEXP to resolve declaration of $ref
      REF_REGEX_1 = /\#\/definitions\/[a-z]\w*\b/ # matches current schema definitions => #/definitions/__any_type_alias_name__
      # REGEXP to resolve declaration of $ref
      REF_REGEX_2 = /[a-z]\w*\b\.json$/ # matches schema filenames => __any_type_alias_name__.json
      # REGEXP to resolve declaration of $ref
      REF_REGEX_3 = /[a-z]\w*\b\.json\#\/definitions\/[a-z]\w*\b/ # matches external schema definitions => __any_type_alias_name__.json/#/definitions/__any_type_alias_name__

      # Alias declarations for easier referencing
      Alias = RBS::AST::Declarations::Alias
      TypeName = RBS::TypeName
      Namespace = RBS::Namespace

      def initialize(options:, stdout:, stderr:)
        @options = options
        @stdout = stdout
        @stderr = stderr
        @name = nil
        @decls = []
      end

      # Returns type name with prefixes & appropriate namespace
      def type_name(name, prefix: nil, absolute: nil)
        TypeName.new(
          name: prefix ? "#{@name}__#{name}".to_sym : name.to_sym,
          namespace: absolute ? Namespace.root : Namespace.empty
        )
      end

      # IMPORTANT: Function invoked to generate RBS from JSON schema
      # Generates RBS from JSON schema after validating options & writes to file/STDOUT
      def generate
        # Validate options received from CLI
        validate_options()

        # Read filename & it's contents
        read_file do |name, json|
          begin
            stdout.puts "\n======= Generating RBS for schema: #{name} =======\n\n"
            # Obtain schema in RUBY's Hash data structure by parsing file content
            schema = JSON.parse(json)
            @name = name
          rescue JSON::ParserError => e
            # Print error message for invalid JSON content
            raise ValidationError.new(message: "Invalid JSON content!\n#{e.full_message}")
          end

          unless (schema.is_a?(Hash) && (schema.key?("$schema") || schema.key?("$id")))
            raise ValidationError.new(message: "Invalid JSON Schema: #{schema}")
          end

          # Parse & generate declarations from `definitions` attribute of the schema
          # SCHEMA_DEFINITIONS[0] => "definitions"
          schema.dig(SCHEMA_DEFINITIONS[0])&.each do |name, definition|
            decl = Alias.new(
              name: type_name(name, prefix: true), # Complete type name of the alias(including prefix)
              type: parse_schema(name, definition), # Obtain type of alias by parsing the schema
              annotations: [],
              location: nil,
              comment: nil
            )
            # Append the declaration if & only if the declaration has a valid RBS::Type assigned
            @decls << decl if !decl.type.nil?
          end

          # Parse & generate declarations from remaining schema content
          decl = Alias.new(
            name: type_name(@name, prefix: false), # Normal type name with no prefix
            type: parse_schema(name, schema), # Obtain type of alias by parsing the rest of the schema
            annotations: [],
            location: nil,
            comment: nil
          )
          # Append the declaration if & only if the declaration has a valid RBS::Type assigned
          @decls << decl if !decl.type.nil?

          # Write output to either a file or STDOUT
          write_output()
          # Reinitialize declarations array to default value, since the declarations have successfully been written to an IO
          @decls = []

          stdout.puts "\n\n======= Completed generating RBS for schema: #{@name} =======\n"
        end
      end

      # Parse JSON schema & return the `RBS::Types` to be assigned
      def parse_schema(key, schema)
        # Default initial value
        type = nil

        # Check for various schema attributes presence
        case
        # SCHEMA_DEFINITIONS[3] => enum => A union of literals
        when schema.key?(SCHEMA_DEFINITIONS[3])
          unless schema[SCHEMA_DEFINITIONS[3]].is_a?(Array)
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[3]}: #{schema[SCHEMA_DEFINITIONS[3]]}")
          end

          # Assign union type
          type = fetch_type("union")
          # Iterate over literals present in enums & append them to union's types
          schema.dig(SCHEMA_DEFINITIONS[3])&.each do |literal|
            # Assign literal type & append to union's types
            type.types << fetch_type("literal", name: literal)
          end
        # SCHEMA_DEFINITIONS[4] => const => A single literal
        when schema.key?(SCHEMA_DEFINITIONS[4])
          # Assign literal type
          type = fetch_type("literal", name: schema.dig(SCHEMA_DEFINITIONS[4]))
        # SCHEMA_DEFINITIONS[7] => items => An array of a particular type or a tuple of different types
        when schema.key?(SCHEMA_DEFINITIONS[7])
          # If `items` is a single schema, then the type is an array with a fixed type parameter
          if (items = schema[SCHEMA_DEFINITIONS[7]]).is_a?(Hash)
            # Assign `class_instance` of Array type
            type = fetch_type("class_instance", name: "Array", absolute: true)
            # Parse `items` schema & assign type parameter of Array
            if !(temp = parse_schema(key, items)).nil?
              type.args << temp # => Array[x]
            end
          # If `items` is an array of schemas, the type is a tuple with different types
          elsif (items = schema[SCHEMA_DEFINITIONS[7]]).is_a?(Array)
            # Assign Tuple type
            type = fetch_type("tuple")
            # Iterate over each `items` schema and append type of element of Tuple
            items.each do |definition|
              # Parse schema & append type of element of Tuple
              if !(temp = parse_schema(key, definition)).nil?
                type.types << temp
              end
            end
          else
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[7]}: #{schema[SCHEMA_DEFINITIONS[7]]}")
          end
        # SCHEMA_DEFINITIONS[1] => properties => Record type
        when schema.key?(SCHEMA_DEFINITIONS[1])
          # Assign record type
          type = fetch_type("record")
          if (nested_schema = schema.dig(SCHEMA_DEFINITIONS[1])).is_a?(Hash)
            # Iterate over `properties` schemas, parse & assign types of each field
            nested_schema.each do |property, definition|
              # Parse schema of individual key/property & assign type to each key/property
              if !(temp = parse_schema(property, definition)).nil?
                type.fields[@options[:stringify_keys] ? property : property.to_sym] = temp
              end
            end
          else
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[1]}: #{schema[SCHEMA_DEFINITIONS[1]]}")
          end
        # SCHEMA_DEFINITIONS[6] => oneOf => A union of types
        when schema.key?(SCHEMA_DEFINITIONS[6])
          # Assign union type
          type = fetch_type("union")
          if (array = schema[SCHEMA_DEFINITIONS[6]]).is_a?(Array)
            # Iterate over each schema & append extracted type to union's types
            array.each do |definition|
              # Parse schema & append extracted type to union's types
              if !(temp = parse_schema(key, definition)).nil?
                type.types << temp
              end
            end
          else
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[6]}: #{schema[SCHEMA_DEFINITIONS[6]]}")
          end
        # SCHEMA_DEFINITIONS[5] => allOf => An intersection of types
        when schema.key?(SCHEMA_DEFINITIONS[5])
          # Assign intersection type
          type = fetch_type("intersection")
          if (array = schema[SCHEMA_DEFINITIONS[5]]).is_a?(Array)
            # Iterate over each schema & append extracted type to interseciton's types
            array.each do |definition|
              # Parse schema & append extracted type to union's types
              if !(temp = parse_schema(key, definition)).nil?
                type.types << temp
              end
            end
          else
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[5]}: #{schema[SCHEMA_DEFINITIONS[5]]}")
          end
        # SCHEMA_DEFINITIONS[2] => type => any type permitted by JSON schema
        when schema.key?(SCHEMA_DEFINITIONS[2])
          case schema[SCHEMA_DEFINITIONS[2]]
          when "integer"
            # If type = "integer", assign a class instance of integer for RBS
            type = fetch_type("class_instance", name: "Integer", absolute: true)
          when "number"
            # If type = "number", assign a class instance of numeric for RBS
            type = fetch_type("class_instance", name: "Numeric", absolute: true)
          when "string"
            # If type = "string", assign a class instance of string for RBS
            type = fetch_type("class_instance", name: "String", absolute: true)
          when "boolean"
            # If type = "boolean", assign a base type of bool for RBS
            type = fetch_type("boolean")
          when "null"
            # If type = "null", assign a base type of nil for RBS
            type = fetch_type("nil")
          when "object", "array"
            # nop
          else
            raise ValidationError.new(message: "Invalid JSON Schema: #{SCHEMA_DEFINITIONS[2]}: #{schema[SCHEMA_DEFINITIONS[2]]}")
          end
        # SCHEMA_DEFINITIONS[8] => $ref => An alias type
        when schema.key?(SCHEMA_DEFINITIONS[8])
          string = schema[SCHEMA_DEFINITIONS[8]]
          case
          when string.eql?("#")
            # If it references itself, assign alias type of itself
            type = fetch_type("alias", name: @name)
          when string.match?(REF_REGEX_2)
            # If it references another file, assign alias type of reference file
            type = fetch_type("alias", name: string.gsub(/\.json$/, ''), prefix: false)
          when string.match?(REF_REGEX_3)
            # If it references definitions of another file, assign alias type of definition present in reference file
            type = fetch_type("alias", name: string.gsub(/\.json\#\/definitions\//, '__'), prefix: false)
          when string.match?(REF_REGEX_1)
            # If it references a definition in the current schema, assign an alias type of that definition
            type = fetch_type("alias", name: string.gsub(/\#\/definitions\//, ''))
          else
            raise ValidationError.new(message: "Could not resolve URI in: #{SCHEMA_DEFINITIONS[8]} = #{schema[SCHEMA_DEFINITIONS[8]]}")
          end
        end

        if type.nil? && !(schema_keys = schema.keys).empty? && !(schema_keys - SCHEMA_DEFINITIONS).empty?
          RBS.logger.warn "#{key} => Unsupported attributes: #{schema_keys.join(", ")}"
        end

        type
      end

      # Returns corresponding `RBS::Types`
      def fetch_type(type, name: nil, absolute: nil, prefix: true)
        case type
        when "union"
          RBS::Types::Union.new(
            types: [],
            location: nil
          )
        when "intersection"
          RBS::Types::Intersection.new(
            types: [],
            location: nil
          )
        when "tuple"
          RBS::Types::Tuple.new(
            types: [],
            location: nil
          )
        when "class_instance"
          RBS::Types::ClassInstance.new(
            name: type_name(name, absolute: absolute),
            args: [],
            location: nil
          )
        when "record"
          RBS::Types::Record.new(
            fields: {},
            location: nil
          )
        when "literal"
          RBS::Types::Literal.new(
            literal: name,
            location: nil
          )
        when "boolean"
          RBS::Types::Bases::Bool.new(
            location: nil
          )
        when "nil"
          RBS::Types::Bases::Nil.new(
            location: nil
          )
        when "alias"
          RBS::Types::Alias.new(
            name: type_name(name, prefix: prefix),
            location: nil
          )
        end
      end

      # Read a given set of file(s)
      def read_file
        # If a single file is given as input
        if (path = @options[:file])
          # Yield filename & file contents
          yield [File.basename(path, ".json"), File.read(path)]
        # If a directory is given as input
        elsif @options[:dir]
          # Iterate over all JSON files present in the directory
          ## Ruby 3.0+ returns files in a sorted order & provides an option to obtain sorted result ##
          (RUBY_VERSION >= '3.0' ? Dir["#{@options[:dir]}*.{json}", sort: true] : Dir["#{@options[:dir]}*.{json}"].sort).each do |file|
            # Yield individual filename & file content
            yield [File.basename(file, ".json"), File.read(file)]
          end
        end
      end

      # Write output using `RBS::Writer` to a particular `IO`
      def write_output
        # If an output directory is given, open a file & write to it
        if @options[:output]
          File.open("#{@options[:output]}#{@name}.rbs", 'w') do |io|
            stdout.puts "Writing output to file: #{@options[:output]}#{@name}.rbs"
            RBS::Writer.new(out: io).write(@decls)
          end
        # If no output directory is given write to STDOUT
        else
          RBS::Writer.new(out: stdout).write(@decls)
        end
      end

      # Validate options given to the CLI
      def validate_options
        path = Pathname(@options[:file] || @options[:dir])
        # Check if a valid file exists?
        raise ValidationError.new(message: "#{@options[:file]}: File not found!") if @options[:file] && !path.file?
        # Check if a valid directory exists?
        raise ValidationError.new(message: "#{@options[:dir]}: Directory not found!") if @options[:dir] && !path.directory?
        # Append a slash, if slash is missing
        @options[:dir] += "/" if @options[:dir] && !(@options[:dir].end_with?("/"))
        if @options[:output]
          path = Pathname(@options[:output])
          # Check if a valid directory exists?
          raise ValidationError.new(message: "#{@options[:output]}: Directory not found!") if !path.directory?
          # Append a slash, if slash is missing
          @options[:output] += "/" if !(@options[:output].end_with?("/"))
        end
      end
    end
  end
end
