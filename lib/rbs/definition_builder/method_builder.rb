# frozen_string_literal: true

module RBS
  class DefinitionBuilder
    class MethodBuilder
      class Methods
        class Definition < Struct.new(:name, :type, :originals, :overloads, :accessibilities, keyword_init: true)
          # @implements Definition

          def original
            originals.first
          end

          def accessibility
            if original.is_a?(AST::Members::Alias)
              raise "alias member doesn't have accessibility"
            else
              accessibilities[0] or raise
            end
          end

          def self.empty(name:, type:)
            new(type: type, name: name, originals: [], overloads: [], accessibilities: [])
          end
        end

        attr_reader :type
        attr_reader :methods

        def initialize(type:)
          @type = type
          @methods = {}
        end

        def validate!
          methods.each_value do |defn|
            if defn.originals.size > 1
              raise DuplicatedMethodDefinitionError.new(
                type: type,
                method_name: defn.name,
                members: defn.originals
              )
            end
          end

          self
        end

        def each(&block)
          if block
            # Yields the original method of an alias before the alias, like the
            # topological sort did, and detects recursive alias definitions on the way
            if methods.each_value.any? {|defn| defn.original.is_a?(AST::Members::Alias) }
              done = {} #: Hash[Definition, bool]
              done.compare_by_identity
              methods.each_value do |defn|
                each_alias_first(defn, done, [], &block)
              end
            else
              methods.each_value(&block)
            end
          else
            enum_for :each
          end
        end

        private

        def each_alias_first(defn, done, visiting, &block)
          return if done[defn]

          if visiting.any? {|other| other.equal?(defn) }
            index = visiting.index {|other| other.equal?(defn) } or raise
            raise RecursiveAliasDefinitionError.new(type: type, defs: visiting[index..] || raise)
          end

          if (member = defn.original).is_a?(AST::Members::Alias)
            if old = methods.fetch(member.old_name, nil)
              # A self alias forms a size-1 SCC that the topological sort yielded as is
              unless old.equal?(defn)
                visiting.push(defn)
                each_alias_first(old, done, visiting, &block)
                visiting.pop
              end
            end
          end

          done[defn] = true
          yield defn
        end
      end

      attr_reader :env
      attr_reader :instance_methods
      attr_reader :singleton_methods
      attr_reader :interface_methods

      def initialize(env:)
        @env = env

        @instance_methods = {}
        @singleton_methods = {}
        @interface_methods = {}
      end

      def build_instance(type_name)
        instance_methods[type_name] ||=
          begin
            entry = env.class_decls[type_name]
            args = entry.type_params.map {|param| Types::Variable.new(name: param.name, location: param.location) }
            type = Types::ClassInstance.new(name: type_name, args: args, location: nil)
            Methods.new(type: type).tap do |methods|
              entry.each_decl do |decl|
                subst = entry.align_params(decl)
                case decl
                when AST::Declarations::Base
                  each_rbs_member_with_accessibility(decl.members) do |member, accessibility|
                    case member
                    when AST::Members::MethodDefinition
                      case member.kind
                      when :instance
                        build_method(
                          methods,
                          type,
                          member: subst ? member.update(overloads: member.overloads.map {|overload| overload.sub(subst) }) : member,
                          accessibility: member.visibility || accessibility
                        )
                      when :singleton_instance
                        build_method(
                          methods,
                          type,
                          member: subst ? member.update(overloads: member.overloads.map {|overload| overload.sub(subst) }) : member,
                          accessibility: :private
                        )
                      end
                    when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
                      if member.kind == :instance
                        build_attribute(methods,
                                        type,
                                        member: subst ? member.update(type: member.type.sub(subst)) : member,
                                        accessibility: member.visibility || accessibility)
                      end
                    when AST::Members::Alias
                      if member.kind == :instance
                        build_alias(methods, type, member: member)
                      end
                    end
                  end
                when AST::Ruby::Declarations::Base
                  decl.members.each do |member|
                    case member
                    when AST::Ruby::Members::DefMember
                      if member.instance?
                        build_method(
                          methods,
                          type,
                          member: member,
                          accessibility: :public
                        )
                      end
                    when AST::Ruby::Members::AttrReaderMember, AST::Ruby::Members::AttrWriterMember, AST::Ruby::Members::AttrAccessorMember
                      build_ruby_attribute(methods, type, member: member, accessibility: :public)
                    end
                  end
                end
              end
            end.validate!
          end
      end

      def build_singleton(type_name)
        singleton_methods[type_name] ||=
          begin
            entry = env.class_decls[type_name]
            type = Types::ClassSingleton.new(name: type_name, location: nil)

            Methods.new(type: type).tap do |methods|
              entry.each_decl do |decl|
                decl.members.each do |member|
                  case member
                  when AST::Members::MethodDefinition
                    if member.singleton?
                      build_method(methods, type, member: member, accessibility: member.visibility || :public)
                    end
                  when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
                    if member.kind == :singleton
                      build_attribute(methods, type, member: member, accessibility: member.visibility || :public)
                    end
                  when AST::Members::Alias
                    if member.kind == :singleton
                      build_alias(methods, type, member: member)
                    end
                  when AST::Ruby::Members::DefMember
                    if member.singleton?
                      build_method(methods, type, member: member, accessibility: :public)
                    end
                  end
                end
              end
            end.validate!
          end
      end

      def build_interface(type_name)
        interface_methods[type_name] ||=
          begin
            entry = env.interface_decls[type_name]
            args = Types::Variable.build(entry.decl.type_params.each.map(&:name))
            type = Types::Interface.new(name: type_name, args: args, location: nil)

            Methods.new(type: type).tap do |methods|
              entry.decl.members.each do |member|
                case member
                when AST::Members::MethodDefinition
                  build_method(methods, type, member: member, accessibility: :public)
                when AST::Members::Alias
                  build_alias(methods, type, member: member)
                end
              end
            end.validate!
          end
      end

      def build_alias(methods, type, member:)
        defn = methods.methods[member.new_name] ||= Methods::Definition.empty(type: type, name: member.new_name)
        defn.originals << member
      end

      def build_attribute(methods, type, member:, accessibility:)
        if member.is_a?(AST::Members::AttrReader) || member.is_a?(AST::Members::AttrAccessor)
          defn = methods.methods[member.name] ||= Methods::Definition.empty(type: type, name: member.name)

          defn.accessibilities << accessibility
          defn.originals << member
        end

        if member.is_a?(AST::Members::AttrWriter) || member.is_a?(AST::Members::AttrAccessor)
          defn = methods.methods[:"#{member.name}="] ||= Methods::Definition.empty(type: type, name: :"#{member.name}=")

          defn.accessibilities << accessibility
          defn.originals << member
        end
      end

      def build_ruby_attribute(methods, type, member:, accessibility:)
        member.names.each do |name|
          if member.is_a?(AST::Ruby::Members::AttrReaderMember) || member.is_a?(AST::Ruby::Members::AttrAccessorMember)
            defn = methods.methods[name] ||= Methods::Definition.empty(type: type, name: name)

            defn.accessibilities << accessibility
            defn.originals << member
          end

          if member.is_a?(AST::Ruby::Members::AttrWriterMember) || member.is_a?(AST::Ruby::Members::AttrAccessorMember)
            defn = methods.methods[:"#{name}="] ||= Methods::Definition.empty(type: type, name: :"#{name}=")

            defn.accessibilities << accessibility
            defn.originals << member
          end
        end
      end

      def build_method(methods, type, member:, accessibility:)
        defn = methods.methods[member.name] ||= Methods::Definition.empty(type: type, name: member.name)

        if member.overloading?
          defn.overloads << member
        else
          defn.accessibilities << accessibility
          defn.originals << member
        end
      end

      def each_rbs_member_with_accessibility(members, accessibility: :public)
        members.each do |member|
          case member
          when AST::Members::Public
            accessibility = :public
          when AST::Members::Private
            accessibility = :private
          else
            yield member, accessibility
          end
        end
      end

      def update(env:, except:)
        MethodBuilder.new(env: env).tap do |copy|
          copy.instance_methods.merge!(instance_methods)
          copy.singleton_methods.merge!(singleton_methods)
          copy.interface_methods.merge!(interface_methods)

          except.each do |type_name|
            copy.instance_methods.delete(type_name)
            copy.singleton_methods.delete(type_name)
            copy.interface_methods.delete(type_name)
          end
        end
      end
    end
  end
end
