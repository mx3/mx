require 'test/unit'
require 'rubygems'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/nexml/nexml_parser')) # update to NeXML, change Nexml to Mx2NeXML

class NexmlTest < ActiveSupport::TestCase

  # legacy code from DBHackathon - users should anticipate using BioRuby to replace this functionality

  def setup
    @file_with_trees = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test_files/mx_dump_trees.xml')))
    @file_without_trees = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test_files/mx_dump_no_trees.xml')))

    @nm = Nexml::Document.new(:file => @file_without_trees)
    @nt = Nexml::Document.new(:file => @file_with_trees)
  end

 # def test_initialization_without_input_fails
 #   assert_raise(Nexml::NexmlError) {Nexml::Document.new()}
 # end

  def test_initialization_without_trees_passses
    assert foo = Nexml::Document.new(:file => @file_without_trees)
  end

  def test_base_attributes_are_read
  end 

  def test_count_of_otus
    foo = Nexml::Document.new(:file => @file_without_trees)
    bar = Nexml::Document.new(:file => @file_with_trees)
    assert_equal 6, foo.all_otus.size
    assert_equal 10, bar.all_otus.size
  end

  def test_count_of_chrs
    foo = Nexml::Document.new(:file => @file_without_trees)
    bar = Nexml::Document.new(:file => @file_without_trees)
    assert_equal 10, bar.all_chrs.size 
    assert_equal 10, foo.all_chrs.size  
  end

  # matrix related tests
  
  def test_that_otu_id_and_label_match
    assert_equal "stuff", @nt.otu_by_id('t10657').attributes['label']  
    assert_equal "things", @nt.otu_by_id('t10658').attributes['label']  
  end
 
# def test_that_chr_id_and_label_match
#   assert_equal 'Tall interntennal flange', @nm.characters['c1514'] 
#   assert_equal 'Head depression', @nm.chrs['c1554'] 
# end

# def test_that_chr_has_proper_states
#   assert_equal 2, @nm.characters['c1554'].codings.size
#   assert_equal "Present",  @nm.chrs['c1554'].codings['cs4059']
# end
   
  def test_cell_contents
  end

  def test_that_the_right_number_of_trees_is_read
    assert_equal 1, @nt.all_trees.size
  end

  def test_return_tree_by_id
    assert_equal "simple_tree_of_10", @nt.tree_by_id('t5').attributes['label']  
  end

  def test_that_tree_has_right_number_of_edges
    assert_equal 16, @nt.tree_by_id('t5').edges.size
  end

  def test_that_tree_has_right_number_of_nodes
    assert_equal 17, @nt.tree_by_id('t5').nodes.size
  end

  def test_root_node
    assert_equal "node_275", @nt.tree_by_id('t5').root_node.attributes['id']
  end

  def test_node_children
    root_node = @nt.tree_by_id('t5').root_node
    assert_equal 1, @nt.tree_by_id('t5').children_of_node(root_node).size
    assert_equal 'node_276', @nt.tree_by_id('t5').children_of_node(root_node)[0].attributes['id']
  
    other_node = @nt.tree_by_id('t5').node_by_id('node_276')
    assert_equal ['node_277', 'node_278', 'node_283'], @nt.tree_by_id('t5').children_of_node(other_node).collect{|n| n.attributes['id']}.sort
  end

# def test_newick_string
#   t = @nt.tree_by_id('t5')
#   assert_equal '(Cat, ((Ant, Cow), Moose), ((Mouse_10, O, Pig, Really_really_really_really_really_really_long_name_for_a_whale_named_sue), (Sheep, Snail)));' , t.newick_string(t.root_node) #(root_node) # "#{@nt.tree_by_id('t5').newick_string(root_node)}"
#   assert_equal '(n275,(n276, (277, 278,((279, (280, 281)), 282)  283, (284,(285,286,287,288), 289 )',  "(#{@nt.tree_by_id('t5').newick_string(root_node)})"
# end

  private
  def read_file_without_trees
    @nf = NexmlParser.new(:file => @file_without_trees)
  end

  def read_file_with_trees
    @nf = NexmlParser.new(:file => @file_with_trees)
  end

end

