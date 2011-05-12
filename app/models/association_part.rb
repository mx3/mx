# == Schema Information
# Schema version: 20090930163041
#
# Table name: association_parts
#
#  id             :integer(4)      not null, primary key
#  association_id :integer(4)      not null
#  position       :integer(4)      not null
#  isa_id         :integer(4)
#  isa_complement :boolean(1)
#  otu_id         :integer(4)      not null
#

class AssociationPart < ActiveRecord::Base
  belongs_to :association
  belongs_to :object_relationship
  belongs_to :otu
  
  acts_as_list :scope => :association  
  
  # :object_relationship is not required! and :association id is added post new, thus validating presence in the present
  # code does not work (it needs to be revamped, but at present works) ???
  validates_presence_of  :otu # :isa, :otu
  
  # to work with html forms, the isa_id thing is negative if we mean the complement of the isa
  def object_relationship_id=(fake_object_relationship)
    self[:object_relationship_id] = fake_object_relationship.to_i.abs
    self[:object_relationship_complement] = (fake_object_relationship.to_i < 0)
  end

  def object_relationship_id
    isa_complement ? - read_attribute(:object_relationship_id) : read_attribute(:object_relationship_id)
  end

end
