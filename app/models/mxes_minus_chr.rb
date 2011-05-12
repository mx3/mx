# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes_minus_chrs
#
#  chr_id :integer(4)      not null
#  mx_id  :integer(4)      not null
#  id     :integer(4)      not null, primary key
#


class MxesMinusChr < ActiveRecord::Base
  belongs_to :mx
  belongs_to :chr

  after_save :remove_from_matrix
  before_destroy :add_to_matrix

  validates_uniqueness_of 'chr_id', :scope => 'mx_id'

  def remove_from_matrix
    cm = ChrsMx.find_by_mx_id_and_chr_id(self.mx_id, self.chr_id)
    Mx.find(self.mx_id).chrs_mxes.destroy(cm) if cm
  end

  def add_to_matrix
    m = Mx.find(self.mx_id)
    m.chrs_mxes.create(:chr_id => self.chr_id, :mx_id => m.id) if m.group_and_plus_chrs.map(&:id).include?(self.chr_id)
  end
    
end
