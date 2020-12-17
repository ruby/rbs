module RBS
  module MethodNameHelper
    def method_name_string()
      separator = case kind
                  when :instance
                    "#"
                  when :singleton
                    "."
                  else
                    raise
                  end

      "#{type_name}#{separator}#{method_name}"
    end
  end

  class InvalidTypeApplicationError < StandardError
    attr_reader :type_name
    attr_reader :args
    attr_reader :params
    attr_reader :location

    def initialize(type_name:, args:, params:, location:)
      @type_name = type_name
      @args = args
      @params = params
      @location = location
      super "#{Location.to_string location}: #{type_name} expects parameters [#{params.join(", ")}], but given args [#{args.join(", ")}]"
    end

    def self.check!(type_name:, args:, params:, location:)
      unless args.size == params.size
        raise new(type_name: type_name, args: args, params: params, location: location)
      end
    end
  end

  class InvalidExtensionParameterError < StandardError
    attr_reader :type_name
    attr_reader :extension_name
    attr_reader :location
    attr_reader :extension_params
    attr_reader :class_params

    def initialize(type_name:, extension_name:, extension_params:, class_params:, location:)
      @type_name = type_name
      @extension_name = extension_name
      @extension_params = extension_params
      @class_params = class_params
      @location = location

      super "#{Location.to_string location}: Expected #{class_params.size} parameters to #{type_name} (#{extension_name}) but has #{extension_params.size} parameters"
    end

    def self.check!(type_name:, extension_name:, extension_params:, class_params:, location:)
      unless extension_params.size == class_params.size
        raise new(type_name: type_name,
                  extension_name: extension_name,
                  extension_params: extension_params,
                  class_params: class_params,
                  location: location)
      end
    end
  end

  class RecursiveAncestorError < StandardError
    attr_reader :ancestors
    attr_reader :location

    def initialize(ancestors:, location:)
      names = ancestors.map do |ancestor|
        case ancestor
        when Definition::Ancestor::Singleton
          "singleton(#{ancestor.name})"
        when Definition::Ancestor::Instance
          if ancestor.args.empty?
            ancestor.name.to_s
          else
            "#{ancestor.name}[#{ancestor.args.join(", ")}]"
          end
        end
      end

      super "#{Location.to_string location}: Detected recursive ancestors: #{names.join(" < ")}"
    end

    def self.check!(self_ancestor, ancestors:, location:)
      case self_ancestor
      when Definition::Ancestor::Instance
        if ancestors.any? {|a| a.is_a?(Definition::Ancestor::Instance) && a.name == self_ancestor.name }
          raise new(ancestors: ancestors + [self_ancestor], location: location)
        end
      when Definition::Ancestor::Singleton
        if ancestors.include?(self_ancestor)
          raise new(ancestors: ancestors + [self_ancestor], location: location)
        end
      end
    end
  end

  class NoTypeFoundError < StandardError
    attr_reader :type_name
    attr_reader :location

    def initialize(type_name:, location:)
      @type_name = type_name
      @location = location

      super "#{Location.to_string location}: Could not find #{type_name}"
    end

    def self.check!(type_name, env:, location:)
      dic = case
            when type_name.class?
              env.class_decls
            when type_name.alias?
              env.alias_decls
            when type_name.interface?
              env.interface_decls
            else
              raise
            end

      dic.key?(type_name) or raise new(type_name: type_name, location: location)

      type_name
    end
  end

  class NoSuperclassFoundError < StandardError
    attr_reader :type_name
    attr_reader :location

    def initialize(type_name:, location:)
      @type_name = type_name
      @location = location

      super "#{Location.to_string location}: Could not find super class: #{type_name}"
    end

    def self.check!(type_name, env:, location:)
      env.class_decls.key?(type_name) or raise new(type_name: type_name, location: location)
    end
  end

  class NoSelfTypeFoundError < StandardError
    attr_reader :type_name
    attr_reader :location

    def initialize(type_name:, location:)
      @type_name = type_name
      @location = location

      super "#{Location.to_string location}: Could not find self type: #{type_name}"
    end

    def self.check!(self_type, env:)
      type_name = self_type.name

      dic = case
            when type_name.class?
              env.class_decls
            when type_name.interface?
              env.interface_decls
            end

      dic.key?(type_name) or raise new(type_name: type_name, location: self_type.location)
    end
  end

  class NoMixinFoundError < StandardError
    attr_reader :type_name
    attr_reader :member

    def initialize(type_name:, member:)
      @type_name = type_name
      @member = member

      super "#{Location.to_string location}: Could not find mixin: #{type_name}"
    end

    def location
      member.location
    end

    def self.check!(type_name, env:, member:)
      dic = case
            when type_name.class?
              env.class_decls
            when type_name.interface?
              env.interface_decls
            end

      dic.key?(type_name) or raise new(type_name: type_name, member: member)
    end
  end

  class DuplicatedMethodDefinitionError < StandardError
    attr_reader :type
    attr_reader :method_name
    attr_reader :members

    def initialize(type:, method_name:, members:)
      @type = type
      @method_name = method_name
      @members = members

      super "#{Location.to_string location}: #{qualified_method_name} has duplicated definitions"
    end

    def qualified_method_name
      case type
      when Types::ClassSingleton
        "#{type.name}.#{method_name}"
      else
        "#{type.name}##{method_name}"
      end
    end

    def location
      members[0].location
    end
  end

  class DuplicatedInterfaceMethodDefinitionError < StandardError
    include MethodNameHelper

    attr_reader :type
    attr_reader :method_name
    attr_reader :member

    def initialize(type:, method_name:, member:)
      @type = type
      @method_name = method_name
      @member = member

      super "#{member.location}: Duplicated method definition: #{qualified_method_name}"
    end

    def qualified_method_name
      case type
      when Types::ClassSingleton
        "#{type.name}.#{method_name}"
      else
        "#{type.name}##{method_name}"
      end
    end
  end

  class UnknownMethodAliasError < StandardError
    attr_reader :original_name
    attr_reader :aliased_name
    attr_reader :location

    def initialize(original_name:, aliased_name:, location:)
      @original_name = original_name
      @aliased_name = aliased_name
      @location = location

      super "#{Location.to_string location}: Unknown method alias name: #{original_name} => #{aliased_name}"
    end
  end

  class SuperclassMismatchError < StandardError
    attr_reader :name
    attr_reader :entry

    def initialize(name:, super_classes:, entry:)
      @name = name
      @entry = entry
      super "#{Location.to_string entry.primary.decl.location}: Superclass mismatch: #{name}"
    end
  end

  class InconsistentMethodVisibilityError < StandardError
    attr_reader :type_name
    attr_reader :method_name
    attr_reader :kind
    attr_reader :member_pairs

    def initialize(type_name:, method_name:, kind:, member_pairs:)
      @type_name = type_name
      @method_name = method_name
      @kind = kind
      @member_pairs = member_pairs

      delimiter = case kind
                  when :instance
                    "#"
                  when :singleton
                    "."
                  end

      super "#{Location.to_string member_pairs[0][0].location}: Inconsistent method visibility: #{type_name}#{delimiter}#{method_name}"
    end
  end

  class InvalidOverloadMethodError < StandardError
    attr_reader :type_name
    attr_reader :method_name
    attr_reader :kind
    attr_reader :members

    def initialize(type_name:, method_name:, kind:, members:)
      @type_name = type_name
      @method_name = method_name
      @kind = kind
      @members = members

      delimiter = case kind
                  when :instance
                    "#"
                  when :singleton
                    "."
                  end

      super "#{Location.to_string members[0].location}: Invalid method overloading: #{type_name}#{delimiter}#{method_name}"
    end
  end

  class GenericParameterMismatchError < StandardError
    attr_reader :name
    attr_reader :decl

    def initialize(name:, decl:)
      @name = name
      @decl = decl
      super "#{Location.to_string decl.location}: Generic parameters mismatch: #{name}"
    end
  end

  class DuplicatedDeclarationError < StandardError
    attr_reader :name
    attr_reader :decls

    def initialize(name, *decls)
      @name = name
      @decls = decls

      super "#{Location.to_string decls.last.location}: Duplicated declaration: #{name}"
    end
  end

  class InvalidVarianceAnnotationError < StandardError
    attr_reader :type_name
    attr_reader :param
    attr_reader :location

    def initialize(type_name:, param:, location:)
      @type_name = type_name
      @param = param
      @location = location

      super "#{Location.to_string location}: Type parameter variance error: #{param.name} is #{param.variance} but used as incompatible variance"
    end
  end

  class RecursiveAliasDefinitionError < StandardError
    attr_reader :type
    attr_reader :defs

    def initialize(type:, defs:)
      @type = type
      @defs = defs

      super "#{Location.to_string location}: Recursive aliases in #{type}: #{defs.map(&:name).join(", ")}"
    end

    def location
      defs[0].original.location
    end
  end
end
