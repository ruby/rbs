# frozen_string_literal: true

module RBS
  class Location
    def inspect
      rks = each_required_key.to_a
      ops = each_optional_key.to_a.map {|x| "?#{x}" }
      src = if source.length <= 1
        source.inspect
      else
        source.each_line.first&.chomp&.inspect
      end
      "#<#{self.class}:#{self.__id__} buffer=#{buffer.name}, start=#{start_line}:#{start_byte_column}, pos=#{start_byte}...#{end_byte}, children=#{(rks + ops).join(",")} source=#{src}>"
    end

    def self.new(buffer_ = nil, start_pos_ = nil, end_pos_ = nil, buffer: nil, start_pos: nil, end_pos: nil)
      __skip__ =
        begin
          if buffer && start_pos && end_pos
            super(buffer, start_pos, end_pos)
          else
            super(buffer_, start_pos_, end_pos_)
          end
        end
    end

    alias aref []

    WithChildren = self

    def start_byte
      buffer.absolute_position(_start_pos) || raise
    end

    def end_byte
      buffer.absolute_position(_end_pos) || raise
    end

    def start_char
      top = buffer.top_buffer
      top.content.byteslice(0, start_byte)&.length || 0
    end

    def end_char
      top = buffer.top_buffer
      top.content.byteslice(0, end_byte)&.length || 0
    end

    # @deprecated Use `start_char` or `start_byte` instead.
    def start_pos
      RBS.print_warning { "`RBS::Location#start_pos` is deprecated. Use `start_char` or `start_byte` instead." }
      start_char
    end

    # @deprecated Use `end_char` or `end_byte` instead.
    def end_pos
      RBS.print_warning { "`RBS::Location#end_pos` is deprecated. Use `end_char` or `end_byte` instead." }
      end_char
    end

    def name
      buffer.name
    end

    def start_line
      start_loc[0]
    end

    def start_byte_column
      start_loc[1]
    end

    def start_char_column
      top = buffer.top_buffer
      line, byte_col = top.pos_to_loc(start_byte)
      line_range = top.ranges[line - 1] or return 0
      top.content.byteslice(line_range.begin, byte_col)&.length || 0
    end

    def end_byte_column
      end_loc[1]
    end

    def end_char_column
      top = buffer.top_buffer
      line, byte_col = top.pos_to_loc(end_byte)
      line_range = top.ranges[line - 1] or return 0
      top.content.byteslice(line_range.begin, byte_col)&.length || 0
    end

    # @deprecated Use `start_byte_column` or `start_char_column` instead.
    def start_column
      RBS.print_warning { "`RBS::Location#start_column` is deprecated. Use `start_byte_column` or `start_char_column` instead." }
      start_byte_column
    end

    def end_line
      end_loc[0]
    end

    # @deprecated Use `end_byte_column` or `end_char_column` instead.
    def end_column
      RBS.print_warning { "`RBS::Location#end_column` is deprecated. Use `end_byte_column` or `end_char_column` instead." }
      end_byte_column
    end

    def start_loc
      @start_loc ||= buffer.top_buffer.pos_to_loc(start_byte)
    end

    def end_loc
      @end_loc ||= buffer.top_buffer.pos_to_loc(end_byte)
    end

    def range
      @range ||= start_byte...end_byte
    end

    def source
      @source ||= (buffer.top_buffer.content.byteslice(start_byte, end_byte - start_byte) || raise)
    end

    def to_s
      "#{name || "-"}:#{start_line}:#{start_byte_column}...#{end_line}:#{end_byte_column}"
    end

    def ==(other)
      other.is_a?(Location) &&
        other.buffer == buffer &&
        other.start_byte == start_byte &&
        other.end_byte == end_byte
    end

    def to_json(state = nil)
      {
        start: {
          line: start_line,
          column: start_byte_column
        },
        end: {
          line: end_line,
          column: end_byte_column
        },
        buffer: {
          name: name&.to_s
        }
      }.to_json(state)
    end

    def self.to_string(location, default: "*:*:*...*:*")
      location&.to_s || default
    end

    def add_required_child(name, range)
      _add_required_child(name, range.begin, range.end)
    end

    def add_optional_child(name, range)
      if range
        _add_optional_child(name, range.begin, range.end)
      else
        _add_optional_no_child(name);
      end
    end

    def each_optional_key(&block)
      if block
        _optional_keys.uniq.each(&block)
      else
        enum_for(:each_optional_key)
      end
    end

    def each_required_key(&block)
      if block
        _required_keys.uniq.each(&block)
      else
        enum_for(:each_required_key)
      end
    end

    def key?(name)
      optional_key?(name) || required_key?(name)
    end

    def optional_key?(name)
      _optional_keys.include?(name)
    end

    def required_key?(name)
      _required_keys.include?(name)
    end

    def local_location
      loc = Location.new(buffer.detach, _start_pos, _end_pos)

      each_optional_key do |key|
        value = self[key]
        if value
          loc.add_optional_child(key, value._start_pos...value._end_pos)
        else
          loc.add_optional_child(key, nil)
        end
      end

      each_required_key do |key|
        value = self[key] or raise
        loc.add_required_child(key, value._start_pos...value._end_pos)
      end

      loc #: self
    end

    def local_source
      local_location.source
    end
  end
end
