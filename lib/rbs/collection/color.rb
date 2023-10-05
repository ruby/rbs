# frozen_string_literal: true

module RBS
  module Collection
    module Color
      def green(string)
        "\e[32m#{string}\e[m"
      end
    end
  end
end
