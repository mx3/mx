# == Schema Information
# Schema version: 20090930163041
#
# Table name: otu_groups_otus
#
#  otu_group_id :integer(4)      not null
#  otu_id       :integer(4)      not null
#  position     :integer(4)
#  id           :integer(4)      not null, primary key
#

class OtuGroupsOtu < ActiveRecord::Base
  belongs_to :otu_group
  belongs_to :otu

  validates_uniqueness_of 'otu_id', :scope => 'otu_group_id'
  acts_as_list :scope => :otu_group

  after_save :add_to_matrix          # sync addition with matrices 
  before_destroy :remove_from_matrix # sync removal with matrices


  def add_to_matrix  
    OtuGroup.find(self.otu_group_id).mxes.each do |mx|
      if !mx.otus_minus.map(&:id).include?(self.otu_id) && !mx.otus.map(&:id).include?(self.otu_id)
        mx.mxes_otus.create(:otu_id => self.otu_id, :mx_id => mx.id) 
      end
    end
  end

  def remove_from_matrix
    mxes = OtuGroup.find(self.otu_group_id).mxes
    return true if mxes.size == 0   
    mxes.each do |m|   
      mo = MxesOtu.find_by_mx_id_and_otu_id(m.id, self.otu_id) # CHECK VS PLUS
      mo.destroy if mo
    end
  end

end
