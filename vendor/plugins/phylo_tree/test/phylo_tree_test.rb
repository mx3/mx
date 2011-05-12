require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/phylo_tree'))

class Test_Node < Test::Unit::TestCase
  def test_node
    n = PhyloTree::Node.new
    n.label = "foo"
    n.branch_length = 32
    3.times {n.children << PhyloTree::Node.new}
    assert_equal(n.label, "foo")
    assert_equal(n.branch_length, 32)
    assert_equal(n.children[0].class, PhyloTree::Node)
    assert_equal(n.children.size, 3)
    assert_equal(n.to_s, "(,,)foo:32")
  end 

  def test_descendants
    n1, n2, n3, n4 = PhyloTree::Node.new, PhyloTree::Node.new, PhyloTree::Node.new, PhyloTree::Node.new
    n3.children << n4
    n2.children << n3
    n1.children << n2
    assert_equal([n2, n3, n4], n1.descendants)
  end

end

class Test_TreeBuilder < Test::Unit::TestCase
  def test_builder
    b = PhyloTree::TreeBuilder.new
    root = b.new_node(nil)
    child = b.new_node(root)
    b.label_node(child, "foo")
    assert_equal(child.label, b.get_tree.children[0].label)
  end
end

# no explicit tests for tokens right now...

class Test_Lexer < Test::Unit::TestCase
  def test_lexer
    lexer = PhyloTree::Lexer.new("()'foo' :0.00,;")
    assert lexer.pop(PhyloTree::Tokens::LParen)
    assert lexer.pop(PhyloTree::Tokens::RParen)
    assert id = lexer.pop(PhyloTree::Tokens::ID)
    assert_equal(id.value, "foo")
    assert lexer.pop(PhyloTree::Tokens::Colon)
    assert num = lexer.pop(PhyloTree::Tokens::Number)
    assert_equal(num.value, 0.0)
    assert lexer.pop(PhyloTree::Tokens::Comma)
    assert lexer.pop(PhyloTree::Tokens::SemiColon)
  end

  def test_lexer_errors
    lexer = PhyloTree::Lexer.new("*&")
    assert_raise(PhyloTree::ParseError) {lexer.peek(PhyloTree::Tokens::ID)}
  end
end

class Test_Parser < Test::Unit::TestCase
  def setup
    # a hash of trees for testing.
    # each pair is of the form 'input => expected output'
    @trees = 
    {
      "A;" => "A;",
      "(,(,,),);" => "(,(,,),);",
      "((A,B),(C,D));" => "((A,B),(C,D));",
      "(Alpha,Beta,Gamma,Delta,,Epsilon,,,)'foo':2.3;" => "(Alpha,Beta,Gamma,Delta,,Epsilon,,,)foo:2.3;",
      "(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);" => "(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);",
      "((raccoon:19.19959,bear:6.80041):0.84600,
      ((sea_lion:11.99700, seal:12.00300):7.52973,    
      ((monkey:100.85930,cat:47.14069):20.59201,weasel:18.87953):2.09460):3.87382,dog:25.46154);" =>  "((raccoon:19.19959,bear:6.80041):0.846,((sea_lion:11.997,seal:12.003):7.52973,((monkey:100.8593,cat:47.14069):20.59201,weasel:18.87953):2.0946):3.87382,dog:25.46154);",
      "(((One:0.2,Two:0.3):0.3,(Three:0.5,Four:0.3):0.2):0.3,Five:0.7):0.0;" => "(((One:0.2,Two:0.3):0.3,(Three:0.5,Four:0.3):0.2):0.3,Five:0.7):0.0;"
    }
  end

  def test_parser
    @trees.each_pair{|input,expected|
      assert_equal(parse_tree(input).to_s + ";", expected)
    }
  end

  def test_parser2
    @t = @trees["A;"]
    assert_equal @t, "A;"
    @t1 = @trees["((A,B),(C,D));"]
    foo = parse_tree(@t1) #  gets the root @node
    assert_equal [nil, nil, "A", "B", "C", "D"], foo.descendants.collect{|c| c.label} 


    recurse(foo)
    # puts foo.children
    # puts foo.descendants.join("|")
  end

  def test_branch_length
    @t1 = @trees['(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);']

    foo = parse_tree(@t1)
    assert_equal 6.0, foo.children[0].branch_length
    # puts foo.children.join(" | ")
    # puts foo.descendants.collect{|o| o.branch_length}.join(" | ")

  end

  # note this is the same as the number of left (or right) parens, i.e. the number of internal edges
  def test_total_depth
    @t1 = @trees["((A,B),(C,D));"]
    foo = parse_tree(@t1) #  gets the root @node

    assert_equal 3, total_depth(foo, 0)

    @t2 = @trees["((raccoon:19.19959,bear:6.80041):0.84600,
      ((sea_lion:11.99700, seal:12.00300):7.52973,    
      ((monkey:100.85930,cat:47.14069):20.59201,weasel:18.87953):2.09460):3.87382,dog:25.46154);"]
      bar = parse_tree(@t2)

      assert_equal 6, total_depth(bar, 0)

      blorf = parse_tree("(A,B,C)")
      assert_equal 1, total_depth(blorf,0)

      blorf2 = parse_tree("((A,B),(C,D),(E,F))")
      assert_equal 4, total_depth(blorf2,0)       
    end

    def test_maxiumum_depth
      foo = parse_tree("((raccoon:19.19959,bear:6.80041):0.84600,((sea_lion:11.99700,seal:12.00300):7.52973,((monkey:100.85930,cat:47.14069):20.59201,weasel:18.87953):2.09460):3.87382,dog:25.46154);")
      assert_equal 4, maximum_depth(foo, 0)
            
      blorf = parse_tree("(A,B,C)")
      assert_equal 1, maximum_depth(blorf, 0)

      blorf1 = parse_tree("((A,(B,(C,(D,E)))))")
      assert_equal 5, maximum_depth(blorf1, 0)    

      blorf2 = parse_tree("((A,B),(C,D),(E,F))")
      assert_equal 2, maximum_depth(blorf2, 0)
      
      blorf9 = parse_tree("((A,B),(C,D),(E,F),(H,I))")
      assert_equal 2, maximum_depth(blorf9, 0)
    end

    def test_odd_tree_1
      @t1 = "(W_ruficeps_1,(((((W_gauldi,((W_rodmani,W_longipes),W_romani)),(Dictyopheltes_2,Dictyopheltes_1,Genus_W)),W_ruficeps_5),W_ruficeps_7),W_ruficeps_8));"
      assert foo = parse_tree(@t1) #  gets the root @node
    end

    def test_node_depth
      @t1 = @trees["(((One:0.2,Two:0.3):0.3,(Three:0.5,Four:0.3):0.2):0.3,Five:0.7):0.0;"]
      foo = parse_tree(@t1) #  gets the root @node
      recurse(foo)
    end

    # helpers/debugging
    def recurse(root)
      puts "label: #{root.label}",  "depth: #{root.depth}", "cumulative bl:#{root.cumulative_branch_length}", "bl: #{root.branch_length}", "\n"
      root.children.collect{|c| recurse(c)}
    end

  end

