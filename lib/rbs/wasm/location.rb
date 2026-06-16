# frozen_string_literal: true

module RBS
  # Pure-Ruby implementation of the primitives that back RBS::Location.
  #
  # On CRuby these come from the C extension (ext/rbs_extension/legacy_location.c).
  # JRuby loads this instead, before rbs/location_aux.rb layers the public API on
  # top, so RBS::Location behaves identically without the native extension.
  class Location
    attr_reader :buffer

    def initialize(buffer, start_pos, end_pos)
      @buffer = buffer
      @start_pos = start_pos
      @end_pos = end_pos
      @required_children = {} #: Hash[Symbol, [ Integer, Integer ]]
      @optional_children = {} #: Hash[Symbol, [ Integer, Integer ]?]
    end

    def _start_pos
      @start_pos
    end

    def _end_pos
      @end_pos
    end

    def _add_required_child(name, start_pos, end_pos)
      @required_children[name] = [start_pos, end_pos]
    end

    def _add_optional_child(name, start_pos, end_pos)
      @optional_children[name] = [start_pos, end_pos]
    end

    def _add_optional_no_child(name)
      @optional_children[name] = nil
    end

    def _required_keys
      @required_children.keys
    end

    def _optional_keys
      @optional_children.keys
    end

    def [](name)
      if (range = @required_children[name])
        return Location.new(@buffer, range[0], range[1])
      end

      if @optional_children.key?(name)
        range = @optional_children[name]
        return range && Location.new(@buffer, range[0], range[1])
      end

      nil
    end
  end
end
