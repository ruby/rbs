# frozen_string_literal: true

module RBS
  class Rewriter
    attr_reader :buffer

    def initialize(buffer)
      raise "Rewriter only supports toplevel buffers" if buffer.parent

      @buffer = buffer
      @rewrites = []
    end

    def rewrite(location, string)
      @rewrites.each do |existing_location, _|
        if location.start_byte < existing_location.end_byte && existing_location.start_byte < location.end_byte
          raise "Overlapping rewrites: #{existing_location} and #{location}"
        end
      end

      @rewrites << [location, string]
      self
    end

    def add_comment(*locations, content:)
      earliest = locations.min_by(&:start_char) or raise "At least one location is required"
      insert_pos = earliest.start_byte
      indent = " " * earliest.start_byte_column

      formatted = format_comment(content, indent)

      loc = Location.new(buffer, insert_pos, insert_pos)
      rewrite(loc, "#{formatted}\n#{indent}")
    end

    def replace_comment(comment, content:)
      location = comment.location or raise "Comment must have a location"
      indent = " " * location.start_byte_column

      rewrite(location, format_comment(content, indent))
    end

    def delete_comment(comment)
      location = comment.location or raise "Comment must have a location"
      line_start = location.start_byte - location.start_byte_column
      line_end = location.end_byte + 1
      loc = Location.new(buffer, line_start, line_end)
      rewrite(loc, "")
    end

    def string
      result = buffer.content.dup

      @rewrites.sort_by { |location, _| location.start_byte }.reverse_each do |location, replacement|
        result.bytesplice(location.start_byte...location.end_byte, replacement)
      end

      result
    end

    private

    def format_comment(content, indent)
      content.lines.map do |line|
        line = line.chomp
        line.empty? ? "#" : "# #{line}"
      end.join("\n#{indent}")
    end
  end
end
