# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module StdlibTest
      # Tests under test/stdlib exist to catch mismatches between RBS signatures and the
      # runtime behavior. An assertion that does not consult RBS keeps passing when the
      # signature is broken, so it does not belong there.
      #
      # Every `assert*`/`refute*` call is an offense unless it is listed in `AllowedMethods`
      # or defined with `def` in the same file (a local helper, whose body is checked too).
      #
      # @example
      #   # bad
      #   assert_equal 3, 1 + 2
      #   assert_raises(ArgumentError) { foo.bar }
      #
      #   # good
      #   assert_send_type "(Integer) -> Integer", 1, :+, 2
      #   assert_send_type_error "() -> bot", ArgumentError, foo, :bar
      class NonTypeAssertion < Base
        MSG = <<~MSG.tr("\n", " ").strip
          `%<method>s` does not check anything against RBS signatures.
          Tests under test/stdlib must fail when the RBS definition is wrong:
          use `assert_send_type` (a narrow method type also pins down which branch of the return type is taken),
          `assert_send_type_error`, or `assert_const_type` instead.
          `assert_type` does not read RBS either, so it is not a substitute.
        MSG

        ASSERTION_NAME = /\A(assert|refute)/

        def on_new_investigation
          @local_helpers = processed_source.ast&.each_node(:def)&.map(&:method_name)&.to_set || Set.new
        end

        def on_send(node)
          return if node.receiver

          if node.method?(:method) && node.first_argument&.sym_type?
            check(node.first_argument, node.first_argument.value)
          else
            check(node.loc.selector, node.method_name)
          end
        end

        private

        def check(location, name)
          return unless ASSERTION_NAME.match?(name)
          return if allowed_methods.include?(name.to_s)
          return if @local_helpers.include?(name)

          add_offense(location, message: format(MSG, method: name))
        end

        def allowed_methods
          cop_config.fetch("AllowedMethods", [])
        end
      end
    end
  end
end
