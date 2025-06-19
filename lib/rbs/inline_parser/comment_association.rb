# frozen_string_literal: true

module RBS
  class InlineParser
    class CommentAssociation
      attr_reader :blocks, :associated_blocks, :start_line_map, :end_line_map

      def initialize(blocks)
        @blocks = blocks.sort_by {|block| block.start_line }
        @associated_blocks = Set[].compare_by_identity

        @start_line_map = {}
        @end_line_map = {}

        blocks.each do |block|
          if block.leading?
            end_line_map[block.end_line] = block
          else
            start_line_map[block.start_line] = block
          end
        end
      end

      def self.build(buffer, result)
        blocks = AST::Ruby::CommentBlock.build(buffer, result.comments)
        new(blocks)
      end

      class Reference
        attr_reader :block

        def initialize(block, association)
          @block = block
          @associated_blocks = association
        end

        def associate!
          @associated_blocks << block
          self
        end

        def associated?
          @associated_blocks.include?(block)
        end
      end

      def leading_block(node)
        start_line = node.location.start_line

        if block = end_line_map.fetch(start_line - 1, nil)
          Reference.new(block, associated_blocks)
        end
      end

      def leading_block!(node)
        if ref = leading_block(node)
          unless ref.associated?
            ref.associate!.block
          end
        end
      end

      def trailing_block(node)
        location =
          if node.is_a?(Prism::Node)
            node.location
          else
            node
          end #: Prism::Location
        end_line = location.end_line
        if block = start_line_map.fetch(end_line, nil)
          Reference.new(block, associated_blocks)
        end
      end

      def trailing_block!(node)
        if ref = trailing_block(node)
          unless ref.associated?
            ref.associate!.block
          end
        end
      end

      def each_enclosed_block(node)
        if block_given?
          start_line = node.location.start_line
          end_line = node.location.end_line

          if start_line+1 < end_line
            ((start_line + 1)...end_line).each do |line|
              if block = end_line_map.fetch(line, nil)
                unless associated_blocks.include?(block)
                  associated_blocks << block
                  yield block
                end
              end
            end
          end
        else
          enum_for :each_enclosed_block, node
        end
      end

      def each_unassociated_block
        if block_given?
          blocks.each do |block|
            unless associated_blocks.include?(block)
              yield block
            end
          end
        else
          enum_for :each_unassociated_block
        end
      end
    end
  end
end
