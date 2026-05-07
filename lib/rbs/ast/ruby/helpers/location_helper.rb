# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Helpers
        module LocationHelper
          def rbs_location(location)
            Location.new(buffer, buffer.character_offset(location.start_offset), buffer.character_offset(location.end_offset))
          end
        end
      end
    end
  end
end
