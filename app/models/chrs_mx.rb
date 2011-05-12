# == Schema Information
# Schema version: 20090930163041
#
# Table name: chrs_mxes
#
#  id         :integer(4)      not null, primary key
#  chr_id     :integer(4)      not null
#  mx_id      :integer(4)      not null
#  position   :integer(4)
#  notes      :text
#  creator_id :integer(4)
#  updator_id :integer(4)
#  updated_on :datetime
#  created_on :datetime
#

class ChrsMx < ActiveRecord::Base
  has_standard_fields
  belongs_to :mx
  belongs_to :chr
  acts_as_list :scope => :mx

  scope :ordered_by_chr_name, :order => 'chrs.name', :include => :chr

  # so we can reorder, i.e. Mx.mxes_otu will always be ordered by position
  scope :from_mx, lambda {|*args| {:conditions => ["chrs_mxes.mx_id = ?", args.first || -1] }} # useful in refs case

  validates_uniqueness_of 'chr_id', :scope => 'mx_id'
end
