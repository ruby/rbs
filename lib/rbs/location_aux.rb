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
      "#<#{self.class}:#{self.__id__} buffer=#{buffer.name}, start=#{start_line}:#{start_column}, pos=#{start_pos}...#{end_pos}, children=#{(rks + ops).join(",")} source=#{src}>"
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

    def name
      buffer.name
    end

    def start_line
      start_loc[0]
    end

    def start_column
      start_loc[1]
    end

    def end_line
      end_loc[0]
    end

    def end_column
      end_loc[1]
    end

    def start_loc
      @start_loc ||= buffer.pos_to_loc(start_pos)
    end

    def end_loc
      @end_loc ||= buffer.pos_to_loc(end_pos)
    end

    def range
      @range ||= start_pos...end_pos
    end

    def source
      @source ||= (buffer.content[range] || raise)
    end

    def to_s
      "#{name || "-"}:#{start_line}:#{start_column}...#{end_line}:#{end_column}"
    end

    def ==(other)
      other.is_a?(Location) &&
        other.buffer == buffer &&
        other.start_pos == start_pos &&
        other.end_pos == end_pos
    end

    def to_json(state = _ = nil)
      {
        start: {
          line: start_line,
          column: start_column
        },
        end: {
          line: end_line,
          column: end_column
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

    def absolute_location()
      if parent = buffer.parent_buffer
        top_buffer = parent.top_buffer
        top_start = buffer.absolute_position(start_pos) or raise
        top_end = buffer.absolute_position(end_pos) or raise

        Location.new(top_buffer, top_start, top_end).tap do |location|
          each_optional_key do |key|
            if loc = self[key]
              opt_start = buffer.absolute_position(loc.start_pos) or raise
              opt_end = buffer.absolute_position(loc.end_pos) or raise
              location.add_optional_child(key, opt_start...opt_end)
            else
              location.add_optional_child(key, nil)
            end
          end
          each_required_key do |key|
            loc = self[key] or raise
            req_start = buffer.absolute_position(loc.start_pos) or raise
            req_end = buffer.absolute_position(loc.end_pos) or raise
            location.add_optional_child(key, req_start...req_end)
          end
        end #: self
      else
        self
      end
    end
  end
end
