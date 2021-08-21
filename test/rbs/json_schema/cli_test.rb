require "test_helper"
require "stringio"
require "rbs/json_schema/cli"

class RBS::JSONSchema::CLITest < Test::Unit::TestCase
  include TestHelper

  CLI = RBS::JSONSchema::CLI
  PATH = Pathname(File.join(__dir__, "../../../schema")).realpath

  def stdout
    @stdout ||= StringIO.new
  end

  def stderr
    @stderr ||= StringIO.new
  end

  def with_cli
    yield CLI.new(stdout: stdout, stderr: stderr)
  ensure
    @stdout = nil
    @stderr = nil
  end

  def test_generation_of_rbs
    with_cli do |cli|
      cli.run(%W(./schema/location.json))
      assert_equal <<-EOF, stdout.string
module Location
  type definitions_point = { line: ::Integer, column: ::Integer }

  type definitions_buffer = { name: ::String | nil }

  type definitions_location = { start: definitions_point, :end => definitions_point, buffer: definitions_buffer }

  type t = definitions_location | nil
end
      EOF
    end

    with_cli do |cli|
      cli.run(%W(--no-stringify-keys ./schema/decls.json))
      assert_equal <<-EOF, stdout.string
module Decls
  type definitions_alias = { declaration: "alias", name: ::String, :type => Types::t, annotations: ::Array[Annotation::t], location: Location::t, comment: Comment::t }

  type definitions_constant = { declaration: "constant", name: ::String, :type => Types::t, location: Location::t, comment: Comment::t }

  type definitions_global = { declaration: "global", name: ::String, :type => Types::t, location: Location::t, comment: Comment::t }

  type definitions_moduletypeparam = { name: ::String, variance: "covariant" | "contravariant" | "invariant", skip_validation: bool }

  type definitions_moduleself = { name: ::String, args: ::Array[Types::t] }

  type definitions_module = { declaration: "module", name: ::String, type_params: { params: ::Array[definitions_moduletypeparam] }, members: ::Array[definitions_classmember], self_types: ::Array[definitions_moduleself], annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_interfacemember = Members::definitions_methoddefinition & { kind: "instance" } | Members::definitions_include | Members::definitions_alias

  type definitions_interface = { declaration: "interface", name: ::String, type_params: { params: ::Array[definitions_moduletypeparam] }, members: ::Array[definitions_interfacemember], annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_classmember = Members::definitions_methoddefinition | Members::definitions_variable | Members::definitions_include | Members::definitions_extend | Members::definitions_prepend | Members::definitions_attribute | Members::definitions_visibility | Members::definitions_alias | definitions_alias | definitions_constant | definitions_class | definitions_module | definitions_interface

  type definitions_class = { declaration: "class", name: ::String, type_params: { params: ::Array[definitions_moduletypeparam] }, members: ::Array[definitions_classmember], :super_class => nil | { name: ::String, args: ::Array[Types::t] }, annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type t = definitions_alias | definitions_constant | definitions_global | definitions_class | definitions_module | definitions_interface
end

module Location
  type definitions_point = { line: ::Integer, column: ::Integer }

  type definitions_buffer = { name: ::String | nil }

  type definitions_location = { start: definitions_point, :end => definitions_point, buffer: definitions_buffer }

  type t = definitions_location | nil
end

module Types
  type definitions_base = { :class => "bool" | "void" | "untyped" | "nil" | "top" | "bot" | "self" | "instance" | "class", location: Location::t }

  type definitions_variable = { :class => "variable", name: ::String, location: Location::t }

  type definitions_classinstance = { :class => "class_instance", name: ::String, args: ::Array[t], location: Location::t }

  type definitions_classsingleton = { :class => "class_singleton", name: ::String, location: Location::t }

  type definitions_interface = { :class => "interface", name: ::String, args: ::Array[t], location: Location::t }

  type definitions_alias = { :class => "alias", name: ::String, location: Location::t }

  type definitions_tuple = { :class => "tuple", types: ::Array[t], location: Location::t }

  type definitions_record = { :class => "record", fields: ::Hash[::String, t], location: Location::t }

  type definitions_union = { :class => "union", types: ::Array[t], location: Location::t }

  type definitions_intersection = { :class => "intersection", types: ::Array[t], location: Location::t }

  type definitions_optional = { :class => "optional", :type => t, location: Location::t }

  type definitions_proc = { :class => "proc", :type => Function::t, location: Location::t }

  type definitions_literal = { :class => "literal", literal: ::String, location: Location::t }

  type t = definitions_base | definitions_variable | definitions_classinstance | definitions_classsingleton | definitions_interface | definitions_alias | definitions_tuple | definitions_record | definitions_union | definitions_intersection | definitions_optional | definitions_proc | definitions_literal
end

module Function
  type definitions_param = { :type => Types::t, name: ::String | nil }

  type t = { required_positionals: ::Array[definitions_param], optional_positionals: ::Array[definitions_param], rest_positionals: definitions_param | nil, trailing_positionals: ::Array[definitions_param], required_keywords: ::Hash[::String, definitions_param], optional_keywords: ::Hash[::String, definitions_param], rest_keywords: definitions_param | nil, :return_type => Types::t }
end

module Annotation
  type t = { string: ::String, location: Location::t }
end

module Comment
  type definitions_comment = { string: ::String, location: Location::t }

  type t = definitions_comment | nil
end

module Methodtype
  type definitions_block = { :type => Function::t, required: bool }

  type t = { type_params: ::Array[::String], :type => Function::t, block: definitions_block | nil, location: Location::t }
end

module Members
  type definitions_methoddefinition = { member: "method_definition", kind: "instance" | "singleton" | "singleton_instance", types: ::Array[Methodtype::t], comment: Comment::t, annotations: ::Array[Annotation::t], attributes: ::Array["incompatible"], location: Location::t, :overload => bool }

  type definitions_variable = { member: "instance_variable" | "class_instance_variable" | "class_variable", name: ::String, :type => Types::t, location: Location::t, comment: Comment::t }

  type definitions_include = { member: "include", name: ::String, args: ::Array[Types::t], annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_extend = { member: "extend", name: ::String, args: ::Array[Types::t], annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_prepend = { member: "prepend", name: ::String, args: ::Array[Types::t], annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_attribute = { member: "attr_reader" | "attr_accessor" | "attr_writer", name: ::String, kind: "instance" | "singleton", :type => Types::t, ivar_name: ::String | nil | false, annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }

  type definitions_visibility = { member: "public" | "private", location: Location::t }

  type definitions_alias = { member: "alias", new_name: ::String, old_name: ::String, kind: "instance" | "singleton", annotations: ::Array[Annotation::t], comment: Comment::t, location: Location::t }
end
      EOF
    end
  end

  def test_output_writing_to_location
    Dir.mktmpdir do |dir|
      with_cli do |cli|
        cli.run(%W(./schema/location.json -o #{dir}))
        assert File.file?("#{dir}/location.rbs")
        assert_equal <<-EOF, File.read("#{dir}/location.rbs")
module Location
  type definitions_point = { line: ::Integer, column: ::Integer }

  type definitions_buffer = { name: ::String | nil }

  type definitions_location = { start: definitions_point, :end => definitions_point, buffer: definitions_buffer }

  type t = definitions_location | nil
end
        EOF
        assert_equal <<-EOF, stdout.string
Writing output to file: #{dir}/location.rbs
        EOF
      end
    end
  end

  def test_validate_options
    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(./schema/does_not_exist.json)) }
      assert_equal "./schema/does_not_exist.json: No such file or directory found!", err.message
    end

    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(./schema/does/not/exist)) }
      assert_equal "./schema/does/not/exist: No such file or directory found!", err.message
    end

    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(./schema/location.json -o /does/not/exist)) }
      assert_equal "/does/not/exist: Directory not found!", err.message
    end

    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(./lib/rbs.rb)) }
      assert_equal "Invalid JSON content!", err.message.split("\n").first
    end
  end
end
