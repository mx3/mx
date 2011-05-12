# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes_plus_otus
#
#  id     :integer(4)      not null, primary key
#  mx_id  :integer(4)      not null
#  otu_id :integer(4)      not null
#

class MxesPlusOtu < ActiveRecord::Base
  # code is nearly identical to mxes_plus_chrs, mayhaps merge to a single model in the future
  
  belongs_to :mx
  belongs_to :otu

  validates_uniqueness_of 'otu_id', :scope => 'mx_id'

  after_save :add_to_matrix
  after_destroy :remove_from_matrix # was before
  
  private
  def add_to_matrix
    mx = Mx.find(self.mx_id)
    if !mx.otus.map(&:id).include?(self.otu_id) && !mx.otus_minus.map(&:id).include?(self.otu_id)
      mx.mxes_otus.create(:otu_id => self.otu_id, :mx_id => self.mx_id)
      mx.save
    end
  end

  def remove_from_matrix
    m = Mx.find(self.mx_id)
    if !m.otus_minus.map(&:id).include?(self.otu_id) && !m.group_and_plus_otus.map(&:id).include?(self.otu_id)
      o = MxesOtu.find_by_otu_id_and_mx_id(self.otu_id, self.mx_id)
      o.destroy if o # because of :dependent chain 
    end
  end

end
