# frozen_string_literal: true

module RBS
  class Buffer
    attr_reader :name
    attr_reader :content
    attr_reader :parent

    def initialize(name: nil, content:, parent: nil)
      case
      when name && content
        @name = name
        @content = content
        @parent = nil
      when parent && content
        @name = parent[0].name
        @content = content
        @parent = parent
      end
    end

    def lines
      ranges.map { self.content[_1] || raise } #$ String
    end

    def line_count
      ranges.size
    end

    def ranges
      @ranges ||= begin
        if content.empty?
          ranges = [0...0] #: Array[Range[Integer]]
          lines = [""]
        else
          lines = content.lines
          lines << "" if content.end_with?("\n")

          ranges = [] #: Array[Range[Integer]]
          offset = 0

          lines.each do |line|
            size0 = line.size
            line = line.chomp
            range = offset...(offset+line.size)
            ranges << range

            offset += size0
          end
        end

        ranges
      end
    end

    def pos_to_loc(pos)
      index = ranges.bsearch_index do |range|
        pos <= range.end ? true : false
      end

      if index
        [index + 1, pos - ranges[index].begin]
      else
        [ranges.size + 1, 0]
      end
    end

    def loc_to_pos(loc)
      line, column = loc

      if range = ranges.fetch(line - 1, nil)
        range.begin + column
      else
        last_position
      end
    end

    def last_position
      if ranges.empty?
        0
      else
        ranges[-1].end
      end
    end

    def inspect
      "#<RBS::Buffer:#{__id__} @name=#{name}, @content=#{content.bytesize} bytes, @lines=#{ranges.size} lines,>"
    end

    def rbs_location(location, loc2=nil)
      if loc2
        Location.new(self.top_buffer, location.start_character_offset, loc2.end_character_offset)
      else
        Location.new(self.top_buffer, location.start_character_offset, location.end_character_offset)
      end
    end

    def sub_buffer(lines:)
      buf = +""
      lines.each_with_index do |range, index|
        start_pos = range.begin
        end_pos = range.end
        slice = content[start_pos...end_pos] or raise
        if slice.include?("\n")
          raise "Line #{index + 1} cannot contain newline character."
        end
        buf << slice
        buf << "\n"
      end

      buf.chomp!

      Buffer.new(content: buf, parent: [self, lines])
    end

    def parent_buffer
      if parent
        parent[0]
      end
    end

    def parent_position(position)
      parent or raise "#parent_position is unavailable with buffer without parent"
      return nil unless position <= last_position

      line, column = pos_to_loc(position)
      parent_range = parent[1][line - 1]
      parent_range.begin + column
    end

    def absolute_position(position)
      if parent_buffer
        pos = parent_position(position) or return
        parent_buffer.absolute_position(pos)
      else
        position
      end
    end

    def top_buffer
      if parent_buffer
        parent_buffer.top_buffer
      else
        self
      end
    end

    def detach
      Buffer.new(name: name, content: content)
    end
  end
end
