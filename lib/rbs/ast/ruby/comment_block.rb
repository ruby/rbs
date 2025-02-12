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

        def translate_comment_position(position)
          start = offsets.bsearch_index { position <= _4 } or return
          offset = offsets[start]

          if offset[2] <= position
            [start, offset[1] + position -  offset[2]]
          end
        end

        def line_start?(position)
          (comment_index, _ = translate_comment_position(position)) or return

          offset = offsets[comment_index]
          line = comment_buffer.lines[comment_index] or raise
          leading_spaces = line.index(/\S/) or return
          content_start_position = leading_spaces + offset[2]

          if position <= content_start_position
            content_start_position
          end
        end
      end
    end
  end
end
