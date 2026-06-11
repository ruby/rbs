# frozen_string_literal: true

# Pure-Ruby implementation of RBS::Location, used by the FFI backend on
# non-MRI Ruby implementations. On MRI the same class is implemented by the
# C extension (ext/rbs_extension/legacy_location.c); this file must match its
# behavior exactly. Common convenience methods live in location_aux.rb, which
# is loaded on top of either implementation.

module RBS
  class Location
    private def initialize(buffer, start_pos, end_pos)
      @buffer = buffer
      @rg_start = start_pos
      @rg_end = end_pos
      @children = nil
    end

    private def initialize_copy(other)
      @buffer = other.buffer
      @rg_start = other._start_pos
      @rg_end = other._end_pos
      @children = other.instance_variable_get(:@children)&.map(&:dup)
      nil
    end

    attr_reader :buffer

    def _start_pos
      @rg_start
    end

    def _end_pos
      @rg_end
    end

    # Children are stored as a flat ordered list of
    # `[name, start_pos, end_pos, required]` entries that permits duplicate
    # names; `[]` returns the first match in insertion order.

    private def _add_required_child(name, start_pos, end_pos)
      (@children ||= []) << [name, start_pos, end_pos, true]
      nil
    end

    private def _add_optional_child(name, start_pos, end_pos)
      (@children ||= []) << [name, start_pos, end_pos, false]
      nil
    end

    private def _add_optional_no_child(name)
      (@children ||= []) << [name, -1, -1, false]
      nil
    end

    private def _optional_keys
      children = @children or return []
      children.reject {|child| child[3] }.map {|child| child[0] }
    end

    private def _required_keys
      children = @children or return []
      children.select {|child| child[3] }.map {|child| child[0] }
    end

    def [](name)
      if children = @children
        children.each do |child|
          if child[0] == name
            if !child[3] && child[1] == -1
              return nil
            else
              return Location.new(@buffer, child[1], child[2])
            end
          end
        end
      end

      raise "Unknown child name given: #{name}"
    end
  end
end
