# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      class CommentBlock
        attr_reader :name, :offsets, :comment_buffer

        def initialize(source_buffer, comments)
          @name = source_buffer.name

          @offsets = []

          # Assume the comment starts with a prefix whitespace
          prefix_str = "# "

          ranges = [] #: Array[Range[Integer]]

          comments.each do |comment|
            tuple = [comment, 2] #: [Prism::Comment, Integer]

            unless comment.location.slice.start_with?(prefix_str)
              tuple[1] = 1
            end

            offsets << tuple

            start_char = comment.location.start_character_offset + tuple[1]
            end_char = comment.location.end_character_offset
            ranges << (start_char ... end_char)
          end

          @comment_buffer = source_buffer.sub_buffer(lines: ranges)
        end

        def leading?
          comment = offsets[0][0] or raise
          comment.location.start_line_slice.index(/\S/) ? false : true
        end

        def trailing?
          comment = offsets[0][0] or raise
          comment.location.start_line_slice.index(/\S/) ? true : false
        end

        def start_line
          comments[0].location.start_line
        end

        def end_line
          comments[-1].location.end_line
        end

        def line_starts
          offsets.map do |comment, prefix_size|
            comment.location.start_character_offset + prefix_size
          end
        end

        def self.build(buffer, comments)
          blocks = [] #: Array[CommentBlock]

          comments = comments.filter {|comment| comment.is_a?(Prism::InlineComment) }

          until comments.empty?
            block_comments = [] #: Array[Prism::Comment]

            until comments.empty?
              comment = comments.first or raise
              last_comment = block_comments.last

              if last_comment
                if last_comment.location.end_line + 1 == comment.location.start_line
                  if last_comment.location.start_column == comment.location.start_column
                    unless comment.location.start_line_slice.index(/\S/)
                      block_comments << comments.shift
                      next
                    end
                  end
                end

                break
              else
                block_comments << comments.shift
              end
            end

            unless block_comments.empty?
              blocks << CommentBlock.new(buffer, block_comments.dup)
            end
          end

          blocks
        end

        AnnotationSyntaxError = _ = Struct.new(:location, :error)

        def each_paragraph(variables, &block)
          if block
            if leading_annotation?(0)
              yield_annotation(0, 0, 0, variables, &block)
            else
              yield_paragraph(0, 0, variables, &block)
            end
          else
            enum_for :each_paragraph, variables
          end
        end

        def yield_paragraph(start_line, current_line, variables, &block)
          # We already know at start_line..current_line are paragraph.

          while true
            next_line = current_line + 1

            if next_line >= comment_buffer.line_count
              yield line_location(start_line, current_line)
              return
            end

            if leading_annotation?(next_line)
              yield line_location(start_line, current_line)
              return yield_annotation(next_line, next_line, next_line, variables, &block)
            else
              current_line = next_line
            end
          end
        end

        def yield_annotation(start_line, end_line, current_line, variables, &block)
          # We already know at start_line..end_line are annotation.
          while true
            next_line = current_line + 1

            if next_line >= comment_buffer.line_count
              annotation = parse_annotation_lines(start_line, end_line, variables)
              yield annotation

              if end_line > current_line
                yield_paragraph(end_line + 1, end_line + 1, variables, &block)
              end

              return
            end

            line_text = text(next_line)
            if leading_spaces = line_text.index(/\S/)
              if leading_spaces == 0
                # End of annotation
                yield parse_annotation_lines(start_line, end_line, variables)

                if leading_annotation?(end_line + 1)
                  yield_annotation(end_line + 1, end_line + 1, end_line + 1, variables, &block)
                else
                  yield_paragraph(end_line + 1, end_line + 1, variables, &block)
                end

                return
              else
                current_line = next_line
                end_line = next_line
              end
            else
              current_line = next_line
            end
          end
        end

        def text(comment_index)
          range = comment_buffer.ranges[comment_index]
          comment_buffer.content[range] or raise
        end

        def line_location(start_line, end_line)
          start_offset = comment_buffer.ranges[start_line].begin
          end_offset = comment_buffer.ranges[end_line].end
          Location.new(comment_buffer, start_offset, end_offset)
        end

        def location()
          first_comment = comments[0] or raise
          last_comment = comments[-1] or raise

          comment_buffer.rbs_location(first_comment.location.join last_comment.location)
        end

        def parse_annotation_lines(start_line, end_line, variables)
          start_pos = comment_buffer.ranges[start_line].begin
          end_pos = comment_buffer.ranges[end_line].end
          begin
            Parser.parse_inline_leading_annotation(comment_buffer, start_pos...end_pos, variables: variables)
          rescue ParsingError => error
            AnnotationSyntaxError.new(line_location(start_line, end_line), error)
          end
        end

        def trailing_annotation(variables)
          if trailing?
            comment = comments[0] or raise
            if comment.location.slice.start_with?(/#[:\[]/)
              begin
                Parser.parse_inline_trailing_annotation(comment_buffer, 0...comment_buffer.last_position, variables: variables)
              rescue ParsingError => error
                location = line_location(0, offsets.size - 1)
                AnnotationSyntaxError.new(location, error)
              end
            end
          end
        end

        def comments
          offsets.map { _1[0]}
        end

        def leading_annotation?(index)
          if index < comment_buffer.line_count
            text(index).start_with?(/@rbs\b/) and return true

            comment = offsets[index][0]
            comment.location.slice.start_with?(/\#:/) and return true
          end

          false
        end

        def as_comment
          lines = [] #: Array[String]

          each_paragraph([]) do |paragraph|
            case paragraph
            when Location
              lines << paragraph.local_source
            end
          end

          string = lines.join("\n")

          unless string.strip.empty?
            AST::Comment.new(string: string, location: location)
          end
        end
      end
    end
  end
end
