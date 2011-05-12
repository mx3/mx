module PhyloTree::Tokens

  class Token 
    # this allows access the the class attribute regexp, without using a class variable
    class << self; attr_reader :regexp; end
    attr_reader :value    
    def initialize(str)
      @value = str
    end
  end

  class LParen < Token
    # in ruby, \A is needed if you want to only match at the beginning of the string.
    @regexp = Regexp.new('\A\s*(\()\s*')
  end

  class RParen < Token
    @regexp = Regexp.new('\A\s*(\))\s*')
  end
  
  # labels
  class ID < Token
    @regexp = Regexp.new('\A\s*((\'[^\']+\')|(\w[^,:(); \t\n]*|_)+)\s*')
    def initialize(str)
      str = str.strip
      str = str[1..-2] if str[0..0] == "'" # get rid of quote marks
      @value = str
    end
  end

  class Colon < Token
    @regexp = Regexp.new('\A\s*(:)\s*')
  end

  class SemiColon < Token
    @regexp = Regexp.new('\A\s*(;)\s*')
  end

  class Comma < Token
    @regexp = Regexp.new('\A\s*(,)\s*')
  end

  class Number < Token
    @regexp = Regexp.new('\A\s*(-?\d+(\.\d+)?([eE][+-]?\d+)?)\s*')
    def initialize(str)
      @value = str.to_f
    end
  end

  def self.phylo_tree_tokens_list
    [
      PhyloTree::Tokens::Number,
      PhyloTree::Tokens::ID, 
      PhyloTree::Tokens::Colon,
      PhyloTree::Tokens::SemiColon,
      PhyloTree::Tokens::Comma,
      PhyloTree::Tokens::LParen,
      PhyloTree::Tokens::RParen,
    ]   
  end
  
end
