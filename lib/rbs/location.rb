module RBS
  class Location
    attr_reader :buffer

    attr_reader :start_pos, :end_pos

    attr_reader :optional_children, :required_children

    def initialize(buffer, start_pos, end_pos)
      @buffer = buffer
      @start_pos = start_pos
      @end_pos = end_pos
      @required_children = {}
      @optional_children = {}
    end

    def initialize_copy(other)
      super

      @required_children = other.required_children.dup
      @optional_children = other.optional_children.dup

      self
    end

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
      buffer.pos_to_loc(start_pos)
    end

    def end_loc
      buffer.pos_to_loc(end_pos)
    end

    def range
      start_pos...end_pos
    end

    def source
      buffer.content[range] || raise
    end

    def to_s
      "#{name || "-"}:#{start_line}:#{start_column}...#{end_line}:#{end_column}"
    end

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

    def freeze
      # raise unless buffer.frozen?
      required_children.freeze
      optional_children.freeze
      super
    end

    def self.build(buffer, start_pos, end_pos, required_children, optional_children)
      loc = Location.new(buffer, start_pos, end_pos)

      required_children.each do |name, range|
        loc.add_required_child(name, range)
      end

      optional_children.each do |name, range|
        loc.add_optional_child(name, range)
      end

      loc.freeze

      loc
    end

    def ==(other)
      other.is_a?(Location) &&
        other.buffer == buffer &&
        other.start_pos == start_pos &&
        other.end_pos == end_pos
    end

    def self.to_string(location, default: "*:*:*...*:*")
      location&.to_s || default
    end

    def add_optional_child(name, range)
      if range
        @optional_children[name] = range
      else
        @optional_children[name] = nil
      end
    end

    def add_required_child(name, range)
      @required_children[name] = range
    end

    def [](name)
      range =
        if required_children.key?(name)
          required_children.fetch(name)
        else
          optional_children.fetch(name, nil)
        end

      if range
        Location.new(buffer, range.begin, range.end)
      end
    end

    alias aref []

    def to_json(state = nil)
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

    def local_location
      loc = Location.new(buffer.detach, start_pos, end_pos)

      each_optional_key do |key|
        value = self[key]
        if value
          loc.add_optional_child(key, value.start_pos...value.end_pos)
        else
          loc.add_optional_child(key, nil)
        end
      end

      each_required_key do |key|
        value = self[key] or raise
        loc.add_required_child(key, value.start_pos...value.end_pos)
      end

      loc #: self
    end

    def local_source
      local_location.source
    end

    def each_optional_key(&block)
      if block
        optional_children.each_key(&block)
      else
        enum_for(:each_optional_key)
      end
    end

    def each_required_key(&block)
      if block
        required_children.each_key(&block)
      else
        enum_for(:each_required_key)
      end
    end

    def optional_key?(name)
      optional_children.key?(name)
    end

    def required_key?(name)
      required_children.key?(name)
    end

    def key?(name)
      optional_key?(name) || required_key?(name)
    end
  end
end
