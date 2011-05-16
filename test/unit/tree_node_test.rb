# == Schema Information
# Schema version: 20090930163041
#
# Table name: tree_nodes
#
#  id                       :integer(4)      not null, primary key
#  parent_id                :integer(4)
#  tree_id                  :integer(4)      not null
#  label                    :string(255)
#  branch_length            :float
#  cumulative_branch_length :float
#  otu_id                   :integer(4)
#  depth                    :integer(4)
#  lft                      :integer(4)
#  rgt                      :integer(4)
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

# TODO: Will be deprecated for the new PhyloDB model


class TreeNodeTest < ActiveSupport::TestCase

  # Make a node and check its attributes.
  def test_creation
    h = {:label => "Coleoptera", :branch_length => 1.2342, :tree_id => 1}
    tn = TreeNode.create!(h)
    h.each do |k,v|
      assert_equal(v, tn[k])
    end
  end
  
#  def test_acts_as_tree
#    a, b, c = Array.new(3) { TreeNode.create!(:tree_id => 1, :lft => 0, :rgt => 0) }
#   b.move_to_child_of(a)
#   c.move_to_child_of(b)
#
#    assert_equal([b], a.children)
#    assert_equal(a, b.parent)
#    assert_equal([c], a.children.first.children)
#    assert_equal(a, c.parent.parent)
#  end
  
end
