# This code was originally translated to Ruby from 
# Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library

module PhyloTree

# silly path games to make the tests run inside rails
require File.expand_path(File.join(File.dirname(__FILE__), 'tokens'))
require File.expand_path(File.join(File.dirname(__FILE__), 'parser'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lexer'))

# representation of a tree (or rather an inner node (=edge?) in a tree).
class Node
  attr_accessor :label, :branch_length, :children, :depth, :cumulative_branch_length

  def initialize
    @children = []
    @label = nil
    @branch_length = nil 
    @depth = nil
    @cumulative_branch_length = nil
  end
  
  def descendants
    @children + @children.map{|c| c.descendants }.flatten
  end
 
  # not used internally
  def to_s
    s = ""
    if not @children.empty?
      s += "(" + @children.collect {|c| c.to_s}.join(",") + ")"
    end
    s += "#{@label}"
    s += ":#{@branch_length}" if @branch_length
    return s
  end

end


class TreeBuilder

  def initialize
    @root = nil
  end

  def new_node(parent)
    n = Node.new
    if parent
      parent.children << n
      n.depth = parent.depth + 1
      # n.cumulative_branch_length = parent.cumulative_branch_length  # this gets added to when bl set
    else
      @root = n
      n.depth = 0
    end
    return n
  end

  def label_node(n, l)
    n.label = l
  end
  
  # branch length, not node depth
  def number_node(n, num)
    n.branch_length = num
    # n.cumulative_branch_length == nil ? n.cumulative_branch_length = num :  n.cumulative_branch_length = (n.cumulative_branch_length + num)
  end

  def get_tree
    @root
  end

end

class ParseError <  StandardError
end

end

def parse_tree(input)
  @i = input 
  builder = PhyloTree::TreeBuilder.new
  lexer = PhyloTree::Lexer.new(@i)
  
  PhyloTree::Parser.new(lexer,builder).parse_node
  return builder.get_tree # returns the root node
end


# returns the number of inner edges (I think), not the maximum depth
def total_depth(node, depth = 0)
  @d = depth
  @d = @d + 1 if node.children.size > 0
  node.children.map{|c| x = total_depth(c,@d) - 1; @d = x if x > @d }
  return @d
end


# returns the value of the depth of the deepest node (starts from 0) 
def maximum_depth(node, depth = 0)
  @h = depth
   node.descendants.map{|d| @h = d.depth if d.depth >= @h }
  @h 
end


# ### --- TNT - specific stuff ------------------------------------------------
# 
# # hmm... lets fudge the builder class around
# class TreeBuilder
# 
#   def label_node(n, l)
#     n.label = l.split("_")[-1]
#   end
# end
# 
# class Node
#   @@num = 0
#   attr_accessor :label, :branch_length, :children
#  
#   def initialize
#     @children = []
#     @label = nil
#     @branch_length = nil
#     # from below
#     @child_labels = {}
#  
#   end
#  
#   def to_s
#     s = ""
#     if not @children.empty?
#       s += "(" + @children.collect {|c| c.to_s}.join(",") + ")"
#     end
#     if @label and @label != ""
#       s += "#{@@num}"
#       @@num += 1
#     end
#     s += "#{@label}"
#     s += ":#{@branch_length}" if @branch_length
#     return s
#   end
#  
#   def build_child_labels
#     for child in @children
#       if not child.children.empty?
#         @child_labels.merge!(child.build_child_labels)
#       else
#         @child_labels[child.label] = true
#       end
#     end
#     return @child_labels
#   end
#  
#   def collapse
#     build_child_labels
#     collapse_by_label
#   end
#  
#   def collapse_by_label
#     for child in @children
#       child.collapse_by_label
#     end
#     if @child_labels and @child_labels.length == 1
#       # not sure of a nice way to do this
#       @child_labels.each_key {|k| @label = "_" + k + "_" }
#       prune_children
#     end
#   end
#  
#   def prune_children
#     for child in @children
#       child.prune_children
#     end
#     @children = []
#   end
# end
# 
# # return an array of trees
# def parse_tnt_file(file_name)
#   trees = []
#   File.open(file_name) {|f|
#     f.each_line {|l|
#       if l[0..0] != "("
#         p "skipped: " + l
#       else
#         l.gsub!(" ", ",")
#         l.gsub!("*", ";")
#         trees << parse_tree(l)
#       end
#     }
#   }
#   return trees
# end
# 
# # output a tree file
# def write_tree_file(file_name, trees)
#   File.open(file_name, "w+") {|f|
#     for t in trees
#       t.collapse
#       f.puts(t.to_s + ";")
#     end 
#   }
# end
#   
#trees = parse_tnt_file("hym18S.tre")

#write_tree_file("hym18S_collapsed.tre", trees)

  
  
  
#  # mockup from Matt
#  class Tree # or PhyloTree perhaps
#  
#   def new(t = '()')
#    parse(t)
#   end
#  
#   def parse
#     # load the nodes
#   end
#  
#  def root
#    # returns the root node, which may or may not be the first terminal listed in the tree (by default set to first)
#  end
#  
#   def validates_as_binary
#     # not important upfront, but useful for some apps which require them  
#   def
#  
#   # immediate children
#   def children(node)
#    # all nodes/terminals from a given node
#   end
#  
#  def immediate_children(node)
#    # nodes/terminals one step up in the tree
#  end
#  
#  def path(start, end, inclusive = true)
#    # returns all nodes ( between the two nodes or a node and terminal, if inclusive then include the start/end points
#  end
#  
#  def path_length(start, end)
#    # return some type of summary of the <value> in (foo:<value>)
#  end
#  
#  def subtree(root)
#   # returns a new Tree object starting from the supplied root node
#  end
#  
#  
#  end
#  
#  class NewickTree << Tree
#   # a subclass that requires a different parsing
#   def parse
#     # load things differently
#    end
#  end
