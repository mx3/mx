# == Schema Information
# Schema version: 20090930163041
#
# Table name: claves
#
#  id              :integer(4)      not null, primary key
#  parent_id       :integer(4)
#  otu_id          :integer(4)
#  couplet_text    :text
#  position        :integer(4)
#  link_out        :text
#  link_out_text   :string(1024)
#  edit_annotation :text
#  pub_annotation  :text
#  head_annotation :text
#  manual_id       :string(7)
#  ref_id          :integer(4)
#  l               :integer(4)
#  r               :integer(4)
#  is_public       :boolean(1)      not null
#  redirect_id     :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

class Clave < ActiveRecord::Base
  self.table_name = 'claves' # spanish for key, which is likely reserved, or will become reserved
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes
  
  acts_as_list :scope => :parent_id
  belongs_to :otu
  belongs_to :ref
  belongs_to :redirection, :class_name => 'Clave', :foreign_key => 'redirect_id' # used to redirect to key to a different (previous or other) couplet

  acts_as_tree :order => "position" ## if abstracting this, we would want to be able to use self.class.order_snippet here

  def display_name(options = {})
    id.to_s + ": " + couplet_text.slice(0..40) + (couplet_text.size > 40 ? '...' : '')
  end

  # take redirection into account
  
  def future # all future nodes taking into account possible redirections
     self.redirect_id.blank? ? self.all_children : self.redirection.all_children
  end
  
  def go_id
    self.redirect_id.blank? ? self.id : self.redirect_id
  end
  
  # *snipped* Taxon Name acts as tree mods, they need modification to work with multiple roots (AFAIKT - matt)

  def dupe(node = self, id = nil)
    a = node.clone
    a.parent_id = id
    a.couplet_text = (a.couplet_text + " (COPY)") if id == nil
    a.save
    
    # clone the figures too
    for f in node.figures
      fnew = f.clone
      fnew.addressable_id = a.id
      fnew.save
    end
    
    for c in node.children
      dupe(c, a.id)
    end
    
    true
  end

  def insert_couplet
   if cs = self.children
    a = cs[0]
    b = cs[1]
   end
   
   c = self.children.create(:couplet_text => 'Child nodes, if present, are attached to this node.')
   d = self.children.create(:couplet_text => 'Inserted node')

   if not a == nil
    a.update_attributes(:parent_id => c.id)
    b.update_attributes(:parent_id => c.id)
   end
 
   [c.id, d.id]
  end
  
  def destroy_couplet # if refactored do with care, parent/child relationships cause some unexpected behaviour
    if cs = self.children(:order => :position)
      a = cs[0]
      b = cs[1]
    end
   
    if (a.children.size == 0) or (b.children.size == 0) # note that this only works when one side of the couplet has no children!
      for c in [a,b]
        for d in c.children
         d.parent = self #update_attributes(:parent_id => self.id)
         d.save!
        end
      end   
       Clave.find(a.id).destroy # NOTE WE CANNOT just do a.destroy, as this invokes bizzare cascading nastiness!!
       Clave.find(b.id).destroy
      true
    else
       false
    end    
  end

  
  def all_children(node = self, result = [], depth = 0) 
    for c in node.children.reverse!  
      c.all_children(c, result, depth + 1)
      a = {}
      a[:depth] = depth
      a[:cpl] = c
      result.push(a)  
    end
    result
  end
  

  def all_children_standard_key(node = self, result = [], depth = 0) # couplets before depth
    @c = node.children
    for c in @c 
      a = {}
      a[:depth] = depth
      a[:cpl] = c
      # a[:couplet_num] = need a different tree traversal to automagically generate couplet numbers, print only uses manually added # at this point 
      result.push(a)  
    end
    
    for c in @c 
      c.all_children_standard_key(c, result, depth + 1)
    end
    result
  end
  
end
