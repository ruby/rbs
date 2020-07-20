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
      last = case last = ancestors.last
             when Definition::Ancestor::Singleton
               "singleton(#{last.name})"
             when Definition::Ancestor::Instance
               if last.args.empty?
                 last.name.to_s
               else
                 "#{last.name}[#{last.args.join(", ")}]"
               end
             end

      super "#{Location.to_string location}: Detected recursive ancestors: #{last}"
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
    attr_reader :decl
    attr_reader :location

    def initialize(decl:, name:, location:)
      decl_str = case decl
                 when AST::Declarations::Interface, AST::Declarations::Class, AST::Declarations::Module
                   decl.name.to_s
                 when AST::Declarations::Extension
                   "#{decl.name} (#{decl.extension_name})"
                 end

      super "#{Location.to_string location}: #{decl_str} has duplicated method definition: #{name}"
    end

    def self.check!(decl:, methods:, name:, location:)
      if methods.key?(name)
        raise new(decl: decl, name: name, location: location)
      end
    end
  end

  class MethodDefinitionConflictWithInterfaceMixinError < StandardError
    include MethodNameHelper

    attr_reader :type_name
    attr_reader :method_name
    attr_reader :kind
    attr_reader :mixin_member
    attr_reader :entries

    def initialize(type_name:, method_name:, kind:, mixin_member:, entries:)
      @type_name = type_name
      @method_name = method_name
      @kind = kind
      @mixin_member = mixin_member
      @entries = entries

      super "#{entries[0].decl.location}: Duplicated method with interface mixin: #{method_name_string}"
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

    def self.check!(methods:, original_name:, aliased_name:, location:)
      unless methods.key?(original_name)
        raise new(original_name: original_name, aliased_name: aliased_name, location: location)
      end
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
    MethodTypeError = Struct.new(:method_name, :method_type, :param, keyword_init: true)
    InheritanceError = Struct.new(:super_class, :param, keyword_init: true)
    MixinError = Struct.new(:include_member, :param, keyword_init: true)

    attr_reader :decl
    attr_reader :errors

    def initialize(decl:, errors:)
      @decl = decl
      @errors = errors

      message = [
        "#{Location.to_string decl.location}: Invalid variance annotation: #{decl.name}"
      ]

      errors.each do |error|
        case error
        when MethodTypeError
          message << "  MethodTypeError (#{error.param.name}): on `#{error.method_name}` #{error.method_type.to_s} (#{error.method_type.location&.start_line})"
        when InheritanceError
          message << "  InheritanceError: #{error.super_class}"
        when MixinError
          message << "  MixinError: #{error.include_member.name} (#{error.include_member.location&.start_line})"
        end
      end

      super message.join("\n")
    end
  end
end
