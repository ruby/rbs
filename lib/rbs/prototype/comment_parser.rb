# frozen_string_literal: true

module RBS
  module Prototype
    module CommentParser
      # Build a line-number-keyed hash of comments from a Prism::ParseResult or
      # an array of Prism comment objects.
      def build_comments_prism(comments, include_trailing:)
        comments.each_with_object({}) do |comment, hash| #$ Hash[Integer, AST::Comment]
          next unless comment.is_a?(Prism::InlineComment)
          next if comment.trailing? && !include_trailing

          line = comment.location.start_line
          body = "#{comment.location.slice}\n"
          body = body[2..-1] or raise
          body = "\n" if body.empty?

          comment = AST::Comment.new(string: body, location: nil)
          if prev_comment = hash.delete(line - 1)
            hash[line] = AST::Comment.new(string: prev_comment.string + comment.string, location: nil)
          else
            hash[line] = comment
          end
        end
      end

      # Parse comments from a Ruby source string. Uses Prism on Ruby >= 3.3,
      # falls back to Ripper on older Rubies.
      if RUBY_VERSION >= "3.3"
        def parse_comments(string, include_trailing:)
          build_comments_prism(
            Prism.parse_comments(string, version: "current"), # steep:ignore UnexpectedKeywordArgument
            include_trailing: include_trailing
          )
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
                next if code_lines[line] && !include_trailing
                body = token[2][2..-1] or raise

                body = "\n" if body.empty?

                comment = AST::Comment.new(string: body, location: nil)
                if prev_comment = hash.delete(line - 1)
                  hash[line] = AST::Comment.new(string: prev_comment.string + comment.string, location: nil)
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
    end
  end
end
