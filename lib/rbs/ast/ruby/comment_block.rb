module RBS
  module AST
    module Ruby
      class CommentBlock
        attr_reader :name, :offsets, :comment_buffer

        def initialize(name, comments)
          @name = name

          @offsets = []

          string = +""

          first_comment = comments.first or raise
          first_content = first_comment.location.slice

          if index = first_content.index(/[^#\s]/)
            if index < first_content.size
              prefix_size = index
            else
              prefix_size = 2
            end
          else
            # Assume other comments has `#` prefix
            prefix_size = 2
          end

          comments.each do |comment|
            tuple = [comment, 0, 0, 0] #: [Prism::Comment, Integer, Integer, Integer]

            line = comment.location.slice.dup
            if line[0, prefix_size] =~ /[^#\s]/
              line[0] = ""
              tuple[1] = 1
            else
              line[0, prefix_size] = ""
              tuple[1] = prefix_size
            end
            tuple[2] = string.size
            string << line
            tuple[3] = string.size
            string << "\n"

            offsets << tuple
          end

          string.chomp!

          @comment_buffer = Buffer.new(name: name, content: string)
        end

        def translate_comment_location(location)
          result = [] #: Array[[Prism::Comment, Integer, Integer]]

          (start_index, start_pos = translate_comment_position(location.start_pos)) or return []
          (end_index, end_pos = translate_comment_position(location.end_pos)) or return []

          if start_index == end_index
            result << [offsets[start_index][0], start_pos, end_pos]
          else
            start_comment, start_prefix, start_start, start_end = offsets[start_index]
            result << [start_comment, start_pos, start_end - start_start + start_prefix]

            ((start_index+1)...end_index).each do |index|
              mid_comment, mid_prefix, mid_start, mid_end = offsets[index]
              result << [mid_comment, mid_prefix, mid_end - mid_start + mid_prefix]
            end

            end_comment, end_prefix, _, _ = offsets[end_index]
            result << [end_comment, end_prefix, end_pos]
          end

          result
        end

        def leading?
          comment = offsets[0][0] or raise
          comment.location.start_line_slice.index(/\S/) ? false : true
        end

        def trailing?
          comment = offsets[0][0] or raise
          comment.location.start_line_slice.index(/\S/) ? true : false
        end

        def translate_comment_position(position)
          start = offsets.bsearch_index { position <= _4 } or return
          offset = offsets[start]

          if offset[2] <= position
            [start, offset[1] + position -  offset[2]]
          end
        end

        def line_starts
          offsets.map do |offset|
            offset[2]
          end
        end

        def self.build(path, comments)
          blocks = [] #: Array[CommentBlock]

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
              blocks << CommentBlock.new(path, block_comments.dup)
            end
          end

          blocks
        end

        AnnotationSyntaxError = _ = Data.define(:location, :error)

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
            # binding.irb

          while true
            next_line = current_line + 1

            if next_line >= comment_buffer.lines.size
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

            if next_line >= comment_buffer.lines.size
              annotation = parse_annotation_lines(start_line, end_line, variables)
              yield annotation

              if end_line > current_line
                yield_paragraph(end_line + 1, end_line + 1, variables, &block)
              end

              return
            end

            line_text = comment_buffer.lines[next_line]
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

        def line_location(start_line, end_line)
          start_offset = offsets[start_line][2]
          end_offset = offsets[end_line][3]
          Location.new(comment_buffer, start_offset, end_offset)
        end

        def parse_annotation_lines(start_line, end_line, variables)
          start_pos = offsets[start_line][2]
          end_pos = offsets[end_line][3]
          begin
            Parser.parse_inline(comment_buffer, start_pos...end_pos, variables: variables)
          rescue ParsingError => error
            AnnotationSyntaxError.new(line_location(start_line, end_line), error)
          end
        end

        def trailing_annotation(variables)
          if trailing?
            comment = comments[0] or raise
            if comment.location.slice.start_with?(/#[:\[]/)
              begin
                Parser.parse_inline_assertion(comment_buffer, 0...comment_buffer.last_position, variables: variables)
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
          if index < comment_buffer.lines.size
            comment_buffer.lines[index].start_with?(/@rbs\b|@rbs!/)
          else
            false
          end
        end

        def slice_after!(array, &block)

        end
      end
    end
  end
end
