# == Schema Information
# Schema version: 20090930163041
#
# Table name: chr_groups_chrs
#
#  chr_group_id :integer(4)      not null
#  chr_id       :integer(4)      not null
#  position     :integer(4)
#  id           :integer(4)      not null, primary key
#

# a join, we need a Model to allow for matrices to be synced

class ChrGroupsChr < ActiveRecord::Base
  belongs_to :chr_group
  belongs_to :chr

  acts_as_list :scope => :chr_group
  
  validates_uniqueness_of 'chr_id', :scope => 'chr_group_id'
  
  # sync with matrices
  after_save :add_to_matrix  
  before_destroy :remove_from_matrix

  def add_to_matrix
    ChrGroup.find(self.chr_group_id).mxes.each do |mx|
      if !mx.chrs_minus.map(&:id).include?(self.chr_id) && !mx.chrs.map(&:id).include?(self.chr_id)
        mx.chrs_mxes.create(:chr_id => self.chr_id, :mx_id => mx.id) 
      end
    end
  end
  
  def remove_from_matrix
    mxes = ChrGroup.find(self.chr_group_id).mxes
    return true if mxes.size == 0   
    mxes.each do |m|   
      cm = ChrsMx.find_by_mx_id_and_chr_id(m.id, self.chr_id) # CHECK VS PLUS?! ... tests don't seem to need it, handled in group
      cm.destroy if cm
    end
  end
  
end
