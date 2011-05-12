# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes_plus_chrs
#
#  chr_id :integer(4)      not null
#  mx_id  :integer(4)      not null
#  id     :integer(4)      not null, primary key
#

class MxesPlusChr < ActiveRecord::Base
  belongs_to :mx
  belongs_to :chr

  validates_uniqueness_of 'chr_id', :scope => 'mx_id'

  after_save :add_to_matrix
  after_destroy :remove_from_matrix

  private
  def add_to_matrix
    # adds unless chr_minus
    mx = Mx.find(self.mx_id)
    if !mx.chrs.map(&:id).include?(self.chr_id) && !mx.chrs_minus.map(&:id).include?(self.chr_id)
      mx.chrs_mxes.create(:chr_id => self.chr_id, :mx_id => self.mx_id)
      mx.save
    end
  end

  def remove_from_matrix
    m = Mx.find(self.mx_id)
    if !m.chrs_minus.map(&:id).include?(self.chr_id) && !m.chrs_from_groups.map(&:id).include?(self.chr_id)
      o = ChrsMx.find_by_chr_id_and_mx_id(self.chr_id, self.mx_id)
      o.destroy if o # because of :dependent chain
    end
  end
end
