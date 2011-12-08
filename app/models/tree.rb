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

class Tree < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes

  require 'phylo_tree'
  require 'nexml/nexml_parser'

  belongs_to :data_source
  has_many :tree_nodes # we can't use :dependent => :destroy because better_nested_set does this for us and we get a conflict, therefor nuke just the root node
  
  before_save :set_max_depth
  after_destroy :delete_tree_nodes # need to do it this way vs. better_nested_set!?
  after_update :delete_tree_nodes # delete them first, then rebuild
  after_save :derive_tree_nodes

  def root_tree_node
    TreeNode.find(:first, :conditions => ["tree_id = ? and parent_id is null", self.id])
  end

  def display_name(options = {})
    name.blank? ? '<i>none provided</i>' :  name
  end
  
  # returns the nodes at depth d
  def nodes_at_depth(d)
    TreeNode.find_by_sql(["Select tn.* from tree_nodes tn WHERE tree_id = ? and depth = ?", self.id, d])
  end
  
  # returns the maximum of nodes_at_depth, should serialize this and store it in a field
  def max_nodes_at_depth
    max = 0
    (0..self.max_depth).each do |i|
      d = self.nodes_at_depth(i).size.to_i
      max = d if d > max
    end
    max
  end
  
  def leaves_at_depth(d)
    @leaves = self.nodes_at_depth(d).inject(0){|leaves, n| leaves + n.leaves_count }
    @leaves
  end
  
  protected
  private
  
  def update_tree_nodes
    delete_tree_nodes
    derive_tree_nodes 
  end
  
  def delete_tree_nodes
    # casade deletes all the children
    TreeNode.find_by_tree_id_and_parent_id(self.id, nil).destroy
  end

  def set_max_depth
    @s = self.tree_string
    pt = parse_tree(@s)
    self.max_depth = maximum_depth(pt, 0)
  end
  
  def derive_tree_nodes
    @s = self.tree_string
    # build the tree here
    pt = parse_tree( @s ) # parsing the string

    begin
      TreeNode.transaction do
        # need to create the first node as a special case, then recurse the rest
        root_node = TreeNode.new(
          #  :lft => -1,
          #  :rgt => -1,
            :tree => self,
            :otu => otu_match(pt.label.to_s),
            :depth => pt.depth,
            :branch_length => pt.branch_length)
        root_node.save # get the lft and rgt
        
        build(pt, root_node) # recursive
      end
    rescue ParseError => e
      raise e
    end
    false
  end

  def build(pt, root_node)
    # recurses and builds tree_nodes from a parse_tree object
    # :lft => -1, :rgt => -1,
    tn = TreeNode.new( :tree_id => self.id, :label => pt.label, :otu => otu_match(pt.label.to_s), :branch_length => pt.branch_length, :depth => pt.depth )
    tn.save
    tn.move_to_child_of root_node
    pt.children.collect{|c| build(c, tn)}
  end
  
  def otu_match(l)
    # logic to try and match OTUs to labels if possible
    # various possibilities here, the logic is basic right now, if label == otu.name, add otu id
    # could extend vs. taxon names etc., but for automation this is likely better done elswhere in a broader context
    return nil if not l
    Otu.find(:first, :conditions => ["proj_id = ? AND name = ?", self.proj_id, l])
  end
  
end
