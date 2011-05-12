# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes_minus_otus
#
#  id     :integer(4)      not null, primary key
#  mx_id  :integer(4)      not null
#  otu_id :integer(4)      not null
#

class MxesMinusOtu < ActiveRecord::Base
  belongs_to :mx
  belongs_to :otu

  after_save :remove_from_matrix
  before_destroy :add_to_matrix

  validates_uniqueness_of 'otu_id', :scope => 'mx_id'

  def remove_from_matrix
    mo = MxesOtu.find_by_mx_id_and_otu_id(self.mx_id, self.otu_id)
    Mx.find(self.mx_id).mxes_otus.destroy(mo) if mo
  end

  def add_to_matrix
    m = Mx.find(self.mx_id)
    m.mxes_otus.create(:otu_id => self.otu_id, :mx_id => m.id) if m.group_and_plus_otus.map(&:id).include?(self.otu_id)
  end

end
