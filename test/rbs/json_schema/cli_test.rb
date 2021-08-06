require "test_helper"
require "stringio"
require "rbs/json_schema/cli"

class RBS::JSONSchema::CLITest < Test::Unit::TestCase
  include TestHelper

  CLI = RBS::JSONSchema::CLI

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

======= Generating RBS for schema: location =======

type location__point = { line: ::Integer, column: ::Integer }

type location__buffer = { name: ::String | nil }

type location__location = { start: location__point, :end => location__point, buffer: location__buffer }

type location = location__location | nil


======= Completed generating RBS for schema: location =======
      EOF
    end

    with_cli do |cli|
      cli.run(%W(--stringify-keys ./schema/location.json))
      assert_equal <<-EOF, stdout.string

======= Generating RBS for schema: location =======

type location__point = { "line" => ::Integer, "column" => ::Integer }

type location__buffer = { "name" => ::String | nil }

type location__location = { "start" => location__point, "end" => location__point, "buffer" => location__buffer }

type location = location__location | nil


======= Completed generating RBS for schema: location =======
      EOF
    end

    with_cli do |cli|
      cli.run(%W(--no-stringify-keys -I ./schema/))
      assert_equal <<-EOF, stdout.string

======= Generating RBS for schema: annotation =======

type annotation = { string: ::String, location: location }


======= Completed generating RBS for schema: annotation =======

======= Generating RBS for schema: comment =======

type comment__comment = { string: ::String, location: location }

type comment = comment__comment | nil


======= Completed generating RBS for schema: comment =======

======= Generating RBS for schema: decls =======

type decls__alias = { declaration: "alias", name: ::String, :type => types, annotations: ::Array[annotation], location: location, comment: comment }

type decls__constant = { declaration: "constant", name: ::String, :type => types, location: location, comment: comment }

type decls__global = { declaration: "global", name: ::String, :type => types, location: location, comment: comment }

type decls__moduleTypeParam = { name: ::String, variance: "covariant" | "contravariant" | "invariant", skip_validation: bool }

type decls__classMember = members__methodDefinition | members__variable | members__include | members__extend | members__prepend | members__attribute | members__visibility | members__alias | decls__alias | decls__constant | decls__class | decls__module | decls__interface

type decls__class = { declaration: "class", name: ::String, type_params: { params: ::Array[decls__moduleTypeParam] }, members: ::Array[decls__classMember], :super_class => nil | { name: ::String, args: ::Array[types] }, annotations: ::Array[annotation], comment: comment, location: location }

type decls__module = { declaration: "module", name: ::String, type_params: { params: ::Array[decls__moduleTypeParam] }, members: ::Array[decls__classMember], self_types: ::Array[decls__moduleSelf], annotations: ::Array[annotation], comment: comment, location: location }

type decls__moduleSelf = { name: ::String, args: ::Array[types] }

type decls__interfaceMember = members__methodDefinition & { kind: "instance" } | members__include | members__alias

type decls__interface = { declaration: "interface", name: ::String, type_params: { params: ::Array[decls__moduleTypeParam] }, members: ::Array[decls__interfaceMember], annotations: ::Array[annotation], comment: comment, location: location }

type decls = decls__alias | decls__constant | decls__global | decls__class | decls__module | decls__interface


======= Completed generating RBS for schema: decls =======

======= Generating RBS for schema: function =======

type function__param = { :type => types, name: ::String | nil }

type function = { required_positionals: ::Array[function__param], optional_positionals: ::Array[function__param], rest_positionals: function__param | nil, trailing_positionals: ::Array[function__param], rest_keywords: function__param | nil, :return_type => types }


======= Completed generating RBS for schema: function =======

======= Generating RBS for schema: location =======

type location__point = { line: ::Integer, column: ::Integer }

type location__buffer = { name: ::String | nil }

type location__location = { start: location__point, :end => location__point, buffer: location__buffer }

type location = location__location | nil


======= Completed generating RBS for schema: location =======

======= Generating RBS for schema: members =======

type members__methodDefinition = { member: "method_definition", kind: "instance" | "singleton" | "singleton_instance", types: ::Array[methodType], comment: comment, annotations: ::Array[annotation], attributes: ::Array["incompatible"], location: location, :overload => bool }

type members__variable = { member: "instance_variable" | "class_instance_variable" | "class_variable", name: ::String, :type => types, location: location, comment: comment }

type members__include = { member: "include", name: ::String, args: ::Array[types], annotations: ::Array[annotation], comment: comment, location: location }

type members__extend = { member: "extend", name: ::String, args: ::Array[types], annotations: ::Array[annotation], comment: comment, location: location }

type members__prepend = { member: "prepend", name: ::String, args: ::Array[types], annotations: ::Array[annotation], comment: comment, location: location }

type members__attribute = { member: "attr_reader" | "attr_accessor" | "attr_writer", name: ::String, kind: "instance" | "singleton", :type => types, ivar_name: ::String | nil | false, annotations: ::Array[annotation], comment: comment, location: location }

type members__visibility = { member: "public" | "private", location: location }

type members__alias = { member: "alias", new_name: ::String, old_name: ::String, kind: "instance" | "singleton", annotations: ::Array[annotation], comment: comment, location: location }


======= Completed generating RBS for schema: members =======

======= Generating RBS for schema: methodType =======

type methodType__block = { :type => function, required: bool }

type methodType = { type_params: ::Array[::String], :type => function, block: methodType__block | nil, location: location }


======= Completed generating RBS for schema: methodType =======

======= Generating RBS for schema: types =======

type types__base = { :class => "bool" | "void" | "untyped" | "nil" | "top" | "bot" | "self" | "instance" | "class", location: location }

type types__variable = { :class => "variable", name: ::String, location: location }

type types__classSingleton = { :class => "class_singleton", name: ::String, location: location }

type types__classInstance = { :class => "class_instance", name: ::String, args: ::Array[types__types], location: location }

type types__interface = { :class => "interface", name: ::String, args: ::Array[types__types], location: location }

type types__alias = { :class => "alias", name: ::String, location: location }

type types__tuple = { :class => "tuple", types: ::Array[types__types], location: location }

type types__record = { :class => "record", location: location }

type types__optional = { :class => "optional", :type => types__types, location: location }

type types__union = { :class => "union", types: ::Array[types__types], location: location }

type types__intersection = { :class => "intersection", types: ::Array[types__types], location: location }

type types__proc = { :class => "proc", :type => function, location: location }

type types__literal = { :class => "literal", literal: ::String, location: location }

type types = types__base | types__variable | types__classInstance | types__classSingleton | types__interface | types__alias | types__tuple | types__record | types__union | types__intersection | types__optional | types__proc | types__literal


======= Completed generating RBS for schema: types =======
      EOF
    end
  end

  def test_output_writing_to_location
    Dir.mktmpdir do |dir|
      with_cli do |cli|
        cli.run(%W(./schema/location.json -o #{dir}))
        assert File.file?("#{dir}/location.rbs")
        assert_equal <<-EOF, File.read("#{dir}/location.rbs")
type location__point = { line: ::Integer, column: ::Integer }

type location__buffer = { name: ::String | nil }

type location__location = { start: location__point, :end => location__point, buffer: location__buffer }

type location = location__location | nil
        EOF
        assert_equal <<-EOF, stdout.string

======= Generating RBS for schema: location =======

Writing output to file: #{dir}/location.rbs


======= Completed generating RBS for schema: location =======
        EOF
      end
    end
  end

  def test_validate_options
    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(./schema/does_not_exist.json)) }
      assert_equal "./schema/does_not_exist.json: File not found!", err.message
    end

    with_cli do |cli|
      err = assert_raises(RBS::JSONSchema::ValidationError) { cli.run(%W(-I ./schema/does/not/exist)) }
      assert_equal "./schema/does/not/exist: Directory not found!", err.message
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
