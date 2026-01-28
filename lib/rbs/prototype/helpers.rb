# frozen_string_literal: true

module RBS
  module Prototype
    module Helpers
      private

      # Prism can't parse Ruby 3.2 code
      if RUBY_VERSION >= "3.3"
        def parse_comments(string, include_trailing:)
          Prism.parse_comments(string, version: "current").yield_self do |prism_comments| # steep:ignore UnexpectedKeywordArgument
            prism_comments.each_with_object({}) do |comment, hash| #$ Hash[Integer, AST::Comment]
              # Skip EmbDoc comments
              next unless comment.is_a?(Prism::InlineComment)
              # skip like `module Foo # :nodoc:`
              next if comment.trailing? && !include_trailing

              line = comment.location.start_line
              body = "#{comment.location.slice}\n"
              body = body[2..-1] or raise
              body = "\n" if body.empty?

              comment = AST::Comment.new(string: body, location: nil)
              if prev_comment = hash.delete(line - 1)
                hash[line] = AST::Comment.new(string: prev_comment.string + comment.string,
                                              location: nil)
              else
                hash[line] = comment
              end
            end
          end
        end
      else
        require "ripper"
        def parse_comments(string, include_trailing:)
          Ripper.lex(string).yield_self do |tokens|
            code_lines = {} #: Hash[Integer, bool]
            tokens.each.with_object({}) do |token, hash| #$ Hash[Integer, AST::Comment]
              case token[1]
              when :on_sp, :on_ignored_nl
                # skip
              when :on_comment
                line = token[0][0]
                # skip like `module Foo # :nodoc:`
                next if code_lines[line] && !include_trailing
                body = token[2][2..-1] or raise

                body = "\n" if body.empty?

                comment = AST::Comment.new(string: body, location: nil)
                if prev_comment = hash.delete(line - 1)
                  hash[line] = AST::Comment.new(string: prev_comment.string + comment.string,
                                                location: nil)
                else
                  hash[line] = comment
                end
              else
                code_lines[token[0][0]] = true
              end
            end
          end
        end
      end

      def block_from_body(node)
        _, args_node, body_node = node.children
        _pre_num, _pre_init, _opt, _first_post, _post_num, _post_init, _rest, _kw, _kwrest, block_var = args_from_node(args_node)

        # @type var body_node: node?
        if body_node
          yields = any_node?(body_node) {|n| n.type == :YIELD }
        end

        if yields || block_var
          required = true

          if body_node
            if any_node?(body_node) {|n| n.type == :FCALL && n.children[0] == :block_given? && !n.children[1] }
              required = false
            end
          end

          if _rest == :* && block_var == :&
            # ... is given
            required = false
          end

          if block_var
            if body_node
              usage = NodeUsage.new(body_node)
              if usage.each_conditional_node.any? {|n| n.type == :LVAR && n.children[0] == block_var }
                required = false
              end
            end
          end

          if yields
            function = Types::Function.empty(untyped)

            yields.each do |yield_node|
              array_content = yield_node.children[0]&.children&.compact || []

              # @type var keywords: node?
              positionals, keywords = if keyword_hash?(array_content.last)
                                        [array_content.take(array_content.size - 1), array_content.last]
                                      else
                                        [array_content, nil]
                                      end

              if (diff = positionals.size - function.required_positionals.size) > 0
                diff.times do
                  function.required_positionals << Types::Function::Param.new(
                    type: untyped,
                    name: nil
                  )
                end
              end

              if keywords
                keywords.children[0].children.each_slice(2) do |key_node, value_node|
                  if key_node
                    key = key_node.children[0]
                    function.required_keywords[key] ||=
                      Types::Function::Param.new(
                        type: untyped,
                        name: nil
                      )
                  end
                end
              end
            end
          else
            function = Types::UntypedFunction.new(return_type: untyped)
          end


          Types::Block.new(required: required, type: function, self_type: nil)
        end
      end

      def each_child(node, &block)
        each_node node.children, &block
      end

      def each_node(nodes)
        nodes.each do |child|
          if child.is_a?(RubyVM::AbstractSyntaxTree::Node)
            yield child
          end
        end
      end

      def any_node?(node, nodes: [], &block)
        if yield(node)
          nodes << node
        end

        each_child node do |child|
          any_node? child, nodes: nodes, &block
        end

        nodes.empty? ? nil : nodes
      end

      def keyword_hash?(node)
        if node && node.type == :HASH
          node.children[0].children.compact.each_slice(2).all? {|key, _|
            symbol_literal_node?(key)
          }
        else
          false
        end
      end

      # NOTE: args_node may be a nil by a bug
      #       https://bugs.ruby-lang.org/issues/17495
      def args_from_node(args_node)
        args_node&.children || [0, nil, nil, nil, 0, nil, nil, nil, nil, nil]
      end

      def symbol_literal_node?(node)
        case node.type
        when :LIT
          if node.children[0].is_a?(Symbol)
            node.children[0]
          end
        when :SYM
          node.children[0]
        end
      end

      def untyped
        @untyped ||= Types::Bases::Any.new(location: nil)
      end
    end
  end
end
