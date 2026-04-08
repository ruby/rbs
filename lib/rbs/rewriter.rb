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
        if location.start_pos < existing_location.end_pos && existing_location.start_pos < location.end_pos
          raise "Overlapping rewrites: #{existing_location} and #{location}"
        end
      end

      @rewrites << [location, string]
      self
    end

    def string
      result = buffer.content.dup

      @rewrites.sort_by { |location, _| location.start_pos }.reverse_each do |location, replacement|
        result[location.start_pos...location.end_pos] = replacement
      end

      result
    end
  end
end
