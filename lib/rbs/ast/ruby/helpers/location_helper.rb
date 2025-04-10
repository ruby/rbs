# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Helpers
        module LocationHelper
          def rbs_location(location)
            Location.new(buffer, location.start_character_offset, location.end_character_offset)
          end
        end
      end
    end
  end
end
