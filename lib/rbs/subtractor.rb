module RBS
  class Subtractor
    # TODO: Should minuend consider use directive?
    def initialize(minuend, subtrahend)
      @minuend = minuend
      @subtrahend = subtrahend
    end

    def call
      @minuend.filter_map do |decl|
        case decl
        #when AST::Declarations::AliasDecl
        when AST::Declarations::Constant
          decl unless @subtrahend.constant_decl?(decl.name.absolute!)
        #when AST::Declarations::Global
        #when AST::Declarations::Class
        else
          raise
        end
      end
    end
  end
end
