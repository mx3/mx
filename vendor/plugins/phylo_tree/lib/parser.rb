class PhyloTree::Parser

  attr_accessor :depth
  
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
    @depth = 0
  end

  def parse_node(parent = nil)
    node = @builder.new_node(parent)
    
    if @lexer.peek(PhyloTree::Tokens::LParen)
      @lexer.pop(PhyloTree::Tokens::LParen) 
      parse_children(node)
      @lexer.pop(PhyloTree::Tokens::RParen)
    end
    if not (@lexer.peek(PhyloTree::Tokens::Comma) or @lexer.peek(PhyloTree::Tokens::SemiColon))

      # add the label to the tree
      @builder.label_node(node, @lexer.pop(PhyloTree::Tokens::ID).value) if @lexer.peek(PhyloTree::Tokens::ID)
      if @lexer.peek(PhyloTree::Tokens::Colon)
        @lexer.pop(PhyloTree::Tokens::Colon)
        
        # add the branch length
        @builder.number_node(node, @lexer.pop(PhyloTree::Tokens::Number).value)
      end
    end
  end

  def parse_children(parent)
     
    # parse a comma-separated list of nodes
    while true 
      parse_node(parent)
      if @lexer.peek(PhyloTree::Tokens::Comma)
        @lexer.pop(PhyloTree::Tokens::Comma)
      else
        break
      end
    end
  end
  
end
