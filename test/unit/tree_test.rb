
# TODO: R3 Deprecation/move to PhyloDB model

# == Schema Information
# Schema version: 20090930163041
#
# Table name: trees
#
#  id             :integer(4)      not null, primary key
#  tree_string    :text(2147483647
#  name           :string(255)
#  data_source_id :integer(4)
#  notes          :text
#  max_depth      :integer(4)
#  proj_id        :integer(4)      not null
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

#require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
#
#require 'tree_node' # tests tree_node as well in various ways
#require 'otu'
#require 'yaml'
#
#class TreeTest < ActiveSupport::TestCase
#
#  def setup
#    # tree examples from Tree_builder plugin
#    $person_id = 1
#    $proj_id = 1
#    @trees = {
#        "1" => "A;",
#        "2" => "(,(,,),);",
#        "3" => "((A,B),(C,D));",
#        "4" => "(Alpha,Beta,Gamma,Delta,,Epsilon,,,)foo:2.3;",
#        "5" => "(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);",
#        "6" => "((raccoon:19.19959,bear:6.80041):0.846,((sea_lion:11.997,seal:12.003):7.52973,((monkey:100.8593,cat:47.14069):20.59201,weasel:18.87953):2.0946):3.87382,dog:25.46154);",
#        "7" => "(E,(A,(B,C,D)));"
#      }
#
#  end
#  
#  def test_new
#    assert_equal  @trees['3'], "((A,B),(C,D));"
#    @tree = Tree.new(:tree_string => @trees['3'])
#  
#    @tree.save
#    assert_equal 8, @tree.tree_nodes.size
#    # puts @tree.tree_nodes.to_yaml
#  end
#
#  def test_new2
#    @tree = Tree.new(:tree_string => '(W_ruficeps_1,(((((W_gauldi,((W_rodmani,W_longipes),W_romani)),(Dictyopheltes_2,Dictyopheltes_1,Genus_W)),W_ruficeps_5),W_ruficeps_7),W_ruficeps_8));')
#    assert @tree.save
#    assert_equal 21, @tree.tree_nodes.size
#  end
#
#  def test_update_attributes
#    @tree = Tree.new(:tree_string => '(W_ruficeps_1,(((((W_gauldi,((W_rodmani,W_longipes),W_romani)),(Dictyopheltes_2,Dictyopheltes_1,Genus_W)),W_ruficeps_5),W_ruficeps_7),W_ruficeps_8));')
#    assert @tree.save
#    assert_equal 21, @tree.tree_nodes.size
#    @tree.reload
#
#    assert d = DataSource.create!(:name => 'foo')
#
#    @tree.update_attributes(:data_source => d, :name => 'foo', :tree_string => '(W_ruficeps_1,(((((W_gauldi,((W_rodmani,W_longipes),W_romani)),(Dictyopheltes_2,Genus_W)),W_ruficeps_5),W_ruficeps_7),W_ruficeps_8));')
#    # assert @tree.save
#    assert_equal 20, @tree.tree_nodes.size
#  end
#
#  def test_new2
#    @tree = Tree.new(:tree_string => '(W_ruficeps_1,(((((W_gauldi,((W_rodmani,W_longipes),W_romani)),(Dictyopheltes_2,Dictyopheltes_1,Genus_W)),W_ruficeps_5),W_ruficeps_7),W_ruficeps_8));')
#    assert @tree.save
#    assert_equal 21, @tree.tree_nodes.size
#  end
#
#
#  def test_root_tree_node
#    @tree = Tree.new(:tree_string => @trees['3']) 
#    @tree.save
#    tn = @tree.root_tree_node
#    assert_equal nil, tn.parent_id
#    assert_equal 1, tn.lft
#  end
#
#  def test_tree_structure
#    # some dummy OTUs to match up with
#    Otu.new(:name => "A").save
#    Otu.new(:name => "B").save
#    
#    @tree = Tree.new(:tree_string => @trees['3']) 
#    @tree.save
#    tn = @tree.root_tree_node
#    assert_equal 7, tn.all_children.size
#    tn1 = tn.children[0]
#    assert_equal 2, tn1.children.size
#    tn2 = tn1.children[0]
#    assert_equal 2, tn2.children.size
#
#    # puts  tn2.children.collect{|c| c.label}
#    assert_equal Otu.find_all_by_name_and_proj_id(["A", "B"], 1), tn2.children.collect{|c| c.otu}
#  end
#  
#  def test_lengths
#    @tree = Tree.new(:tree_string => @trees['5']) 
#    @tree.save
#    tn = @tree.root_tree_node
#    # assert_equal 6.0, tn.branch_length
#  end
#  
#  def test_depth
#    @tree = Tree.new(:tree_string => @trees['5']) 
#    @tree.save
#    # "(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);",
#    assert_equal 2, @tree.max_depth
#
#    @tree2 = Tree.new(:tree_string => @trees['6']) 
#    @tree2.save
#    # "(B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,:11.0);",
#    assert_equal 4, @tree2.max_depth
#
#  end
#  
#  def test_destroy
#    TreeNode.find(:all).map{|o| o.destroy}
#    @tree = Tree.new(:tree_string => @trees['5']) 
#    @tree.save!
#    
#    @tree.destroy
#    assert_equal 0, TreeNode.find(:all).size
#  end
#  
#  def test_draw_nodes  
#    @tree = Tree.new(:tree_string => "(E,(A,(B,C,D)));") 
#    @tree.save!
#    
#    # the string parsing seems to be inserting an extra level at the root
#    root = @tree.root_tree_node.children.first
#    
#    assert_equal [0.0, 2.5], root.draw
#    assert_equal [1.0, 4.5], root.draw(1,2)
#    assert_equal [2.0, 2.5], root.children[0].draw(1,2) # E
#    
#    assert_equal [2.0, 0.5], root.children[1].children[0].draw # A
#    assert_equal [2.0, 1.5], root.children[1].children[1].draw # parent of B
#
#    assert_equal [3.0, 0.5], root.children[1].children[1].children[0].draw # B
#    assert_equal [3.0, 0.5], root.children[1].children[1].children[1].draw # C
#    assert_equal [3.0, 0.5], root.children[1].children[1].children[2].draw # D
#  end
#  
#end
