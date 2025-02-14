module RBS
  module Inline
    class AnnotationParser
      attr_reader :block, :diagnostics

      def initialzie(block)
        @block = block
        @diagnostics = []
      end

      def parse_annotation(index)

      end

      def parse_rbs_annotation(index)

      end

      def parse_colon_annotation(index)
        parser = Parser.new(block.comment_buffer.content, index)
        parser.parse()
      end

      class Parser
        attr_reader :scanner

        KEYWORDS = {
          "@rbs" => :kRBS,
          "return" => :kRETURN,
        }

        PUNCTS = {
          ":" => :kCOLON,
          "--" => :kDASHDASH,
          "?" => :kQUESTION,
          "&" => :kAMP,
        }

        KEYWORDS_RE = /#{Regexp.union(KEYWORDS.each_key.map {|k| Regexp.escape(k) })}\b/
        PUNCTS_RE = Regexp.union(PUNCTS.each_key.map {|k| Regexp.escape(k) })

        def initialize(string, index)
          @scanner = StringScanner.new(string)
          leading = string[0, index] or raise
          @scanner.pointer = leading.bytesize
          @charpos = index
          advance_token()
        end

        def advance_token
          type = nil #: Symbol?

          case
          when scanner.scan(/\s+/)
            @charpos += (scanner.matched || raise).size
            return advance_token()
          when scanner.scan(KEYWORDS_RE)
            type = KEYWORDS.fetch(scanner.matched || raise)
          when scanner.scan(PUNCTS_RE)
            type = PUNCTS.fetch(scanner.matched || raise)
          end

          if type
            matched = scanner.matched or raise
            @current_token = [type, matched, charpos]
            @charpos += matched.size
          end
        end
      end
    end
  end
end
