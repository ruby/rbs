# frozen_string_literal: true

module RBS
  module Prototype
    module Helpers
      private

      def process_comments(comments, include_trailing:)
        comments.each_with_object({}) do |comment, hash| #$ Hash[Integer, AST::Comment]
          # Skip EmbDoc comments
          next unless comment.is_a?(Prism::InlineComment)
          # skip like `module Foo # :nodoc:`
          next if comment.trailing? && !include_trailing

          line = comment.location.start_line
          body = "#{comment.slice}\n"
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
  end
end
