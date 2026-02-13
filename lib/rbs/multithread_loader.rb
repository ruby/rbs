# frozen_string_literal: true

module RBS
  class MultithreadLoader
    class TypeNameEnumerator
      attr_reader :names, :aliases

      def initialize()
        @names = Set.new
        @aliases = {}
      end

      def enumerate(decl, parent, context)
        case decl
        when RBS::AST::Declarations::Class, RBS::AST::Declarations::Module
          full_name = decl.name.with_prefix(parent)
          names << full_name
          ns = full_name.to_namespace
          decl.members.each do |member|
            if member.is_a?(RBS::AST::Declarations::Base)
              enumerate(member, ns, [context, full_name])
            end
          end
        when RBS::AST::Declarations::Interface, RBS::AST::Declarations::TypeAlias
          full_name = decl.name.with_prefix(parent)
          names << full_name
        when RBS::AST::Declarations::ClassAlias, RBS::AST::Declarations::ModuleAlias
          full_name = decl.new_name.with_prefix(parent)
          aliases[full_name] = [decl.old_name, context]
        end
      end
    end

    class ASTResolver
      attr_reader :resolver, :map

      def initialize(resolver, map)
        @resolver = resolver
        @map = map
      end

      def resolve_type_name(type_name, context)
        re = map.resolve(type_name)
        if re.absolute?
          return re
        end
        resolver.resolve(type_name, context: context) || raise("Unresolved type name: #{type_name} in #{context.inspect}")
      end

      def resolve_type(type, context)
        type.map_type_name do |type_name, _, _|
          resolve_type_name(type_name, context)
        end
      end

      def concat_namespace(namespace, typename)
        if typename.namespace.empty?
          path = namespace.path.dup
        else
          path = namespace.path + typename.namespace.path
        end
        path << typename.name
        Namespace.new(absolute: true, path: path)
      end

      def resolve_type_params(params, context)
        params.map do |param|
          param.map_type {|type| _ = resolve_type(type, context) }
        end
      end

      def resolve_decl(decl, context, prefix)
        if decl.is_a?(AST::Declarations::Global)
          # @type var decl: AST::Declarations::Global
          return AST::Declarations::Global.new(
            name: decl.name,
            type: resolve_type(decl.type, nil),
            location: decl.location,
            comment: decl.comment,
            annotations: decl.annotations
          )
        end

        case decl
        when AST::Declarations::Class
          outer_context = context
          inner_context = [context, decl.name.with_prefix(prefix)] #: Resolver::context

          prefix_ = concat_namespace(prefix, decl.name)

          AST::Declarations::Class.new(
            name: decl.name.with_prefix(prefix),
            type_params: resolve_type_params(decl.type_params, inner_context),
            super_class: decl.super_class&.yield_self do |super_class|
              AST::Declarations::Class::Super.new(
                name: resolve_type_name(super_class.name, outer_context),
                args: super_class.args.map {|type| resolve_type(type, outer_context) },
                location: super_class.location
              )
            end,
            members: decl.members.map do |member|
              case member
              when AST::Members::Base
                resolve_member(member, inner_context)
              when AST::Declarations::Base
                resolve_decl(member, inner_context, prefix_)
              else
                raise
              end
            end,
            location: decl.location,
            annotations: decl.annotations,
            comment: decl.comment
          )

        when AST::Declarations::Module
          outer_context = context
          inner_context = [outer_context, decl.name.with_prefix(prefix)] #: Resolver::context

          prefix_ = concat_namespace(prefix, decl.name)
          AST::Declarations::Module.new(
            name: decl.name.with_prefix(prefix),
            type_params: resolve_type_params(decl.type_params, inner_context),
            self_types: decl.self_types.map do |module_self|
              AST::Declarations::Module::Self.new(
                name: resolve_type_name(module_self.name, inner_context),
                args: module_self.args.map {|type| resolve_type(type, inner_context) },
                location: module_self.location
              )
            end,
            members: decl.members.map do |member|
              case member
              when AST::Members::Base
                resolve_member(member, inner_context)
              when AST::Declarations::Base
                resolve_decl(member, inner_context, prefix_)
              else
                raise
              end
            end,
            location: decl.location,
            annotations: decl.annotations,
            comment: decl.comment
          )

        when AST::Declarations::Interface
          AST::Declarations::Interface.new(
            name: decl.name.with_prefix(prefix),
            type_params: resolve_type_params(decl.type_params, context),
            members: decl.members.map do |member|
              resolve_member(member, context)
            end,
            comment: decl.comment,
            location: decl.location,
            annotations: decl.annotations
          )

        when AST::Declarations::TypeAlias
          AST::Declarations::TypeAlias.new(
            name: decl.name.with_prefix(prefix),
            type_params: resolve_type_params(decl.type_params, context),
            type: resolve_type(decl.type, context),
            location: decl.location,
            annotations: decl.annotations,
            comment: decl.comment
          )

        when AST::Declarations::Constant
          AST::Declarations::Constant.new(
            name: decl.name.with_prefix(prefix),
            type: resolve_type(decl.type, context),
            location: decl.location,
            comment: decl.comment,
            annotations: decl.annotations
          )

        when AST::Declarations::ClassAlias
          AST::Declarations::ClassAlias.new(
            new_name: decl.new_name.with_prefix(prefix),
            old_name: resolve_type_name(decl.old_name, context),
            location: decl.location,
            comment: decl.comment,
            annotations: decl.annotations
          )

        when AST::Declarations::ModuleAlias
          AST::Declarations::ModuleAlias.new(
            new_name: decl.new_name.with_prefix(prefix),
            old_name: resolve_type_name(decl.old_name, context),
            location: decl.location,
            comment: decl.comment,
            annotations: decl.annotations
          )
        end
      end

      def resolve_method_type(method_type, context)
        method_type.map_type do |ty|
          resolve_type(ty, context)
        end.map_type_bound do |bound|
          _ = resolve_type(bound, context)
        end
      end

      def resolve_member(member, context)
        case member
        when AST::Members::MethodDefinition
          AST::Members::MethodDefinition.new(
            name: member.name,
            kind: member.kind,
            overloads: member.overloads.map do |overload|
              overload.update(
                method_type: resolve_method_type(overload.method_type, context)
              )
            end,
            comment: member.comment,
            overloading: member.overloading?,
            annotations: member.annotations,
            location: member.location,
            visibility: member.visibility
          )
        when AST::Members::AttrAccessor
          AST::Members::AttrAccessor.new(
            name: member.name,
            type: resolve_type(member.type, context),
            kind: member.kind,
            annotations: member.annotations,
            comment: member.comment,
            location: member.location,
            ivar_name: member.ivar_name,
            visibility: member.visibility
          )
        when AST::Members::AttrReader
          AST::Members::AttrReader.new(
            name: member.name,
            type: resolve_type(member.type, context),
            kind: member.kind,
            annotations: member.annotations,
            comment: member.comment,
            location: member.location,
            ivar_name: member.ivar_name,
            visibility: member.visibility
          )
        when AST::Members::AttrWriter
          AST::Members::AttrWriter.new(
            name: member.name,
            type: resolve_type(member.type, context),
            kind: member.kind,
            annotations: member.annotations,
            comment: member.comment,
            location: member.location,
            ivar_name: member.ivar_name,
            visibility: member.visibility
          )
        when AST::Members::InstanceVariable
          AST::Members::InstanceVariable.new(
            name: member.name,
            type: resolve_type(member.type, context),
            comment: member.comment,
            location: member.location
          )
        when AST::Members::ClassInstanceVariable
          AST::Members::ClassInstanceVariable.new(
            name: member.name,
            type: resolve_type(member.type, context),
            comment: member.comment,
            location: member.location
          )
        when AST::Members::ClassVariable
          AST::Members::ClassVariable.new(
            name: member.name,
            type: resolve_type(member.type, context),
            comment: member.comment,
            location: member.location
          )
        when AST::Members::Include
          AST::Members::Include.new(
            name: resolve_type_name(member.name, context),
            args: member.args.map {|type| resolve_type(type, context) },
            comment: member.comment,
            location: member.location,
            annotations: member.annotations
          )
        when AST::Members::Extend
          AST::Members::Extend.new(
            name: resolve_type_name(member.name, context),
            args: member.args.map {|type| resolve_type(type, context) },
            comment: member.comment,
            location: member.location,
            annotations: member.annotations
          )
        when AST::Members::Prepend
          AST::Members::Prepend.new(
            name: resolve_type_name(member.name, context),
            args: member.args.map {|type| resolve_type(type, context) },
            comment: member.comment,
            location: member.location,
            annotations: member.annotations
          )
        else
          member
        end
      end

      def self.build(resolver, table, dirs)
        map = Environment::UseMap.new(table: table)
        dirs.each do |dir|
          case dir
          when AST::Directives::Use
            dir.clauses.each do |clause|
              map.build_map(clause)
            end
          end
        end

        new(resolver, map)
      end
    end
  end
end
