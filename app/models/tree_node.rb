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

class TreeNode < ActiveRecord::Base
  belongs_to :tree
  belongs_to :otu

  if self.table_exists? # don't run this on migrations TODO (minor): this is odd
    acts_as_nested_set :scope => :tree
  end

  # root - root item of the tree (the one that has a nil parent)
  # roots - root items, in case of multiple roots (the ones that have a nil parent)
  # level - number indicating the level, a root being level 0
  # ancestors - array of all parents, with root as first item
  # self_and_ancestors - array of all parents and self
  # siblings - array of all siblings (items sharing the same parent)
  # self_and_siblings - array of itself and all siblings
  # children_count - count of all nested children
  # children - array of all immediate children
  # all_children - array of all children and nested children
  # full_set - array of itself and all children and nested children
  # leaves - array of the children of this node who do not have children
  # leaves_count - the number of leaves
  # check_subtree - check the left/right indexes of this node and all descendants
  # check_full_tree - check the whole tree this node belongs to
  # renumber_full_tree - recreate the left/right indexes for the whole tree

  after_update :update_tree_string
  # need to update Tree.tree_string on update, if we check for unique names first then we could gsub it
  
  #  def update_tree_string
  #    @t = Tree.find(self.tree_id)
  #    @t.tree_string.gsub!(//)   
  # end
  
  def display_name(options = {})
    label ? label : '<i> no label provided </i>'
  end
  
  def pct_depth
    (self.depth.to_f / self.tree.max_depth.to_f).to_f
  end
  
  # hackin'
  def draw(x_offset = 0, y_offset = 0)
    x = self.depth.to_f + x_offset
    y = (self.leaves.size.to_f / 2) + y_offset
    
    return [x,y]
  end
  
end
