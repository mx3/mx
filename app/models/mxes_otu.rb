# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes_otus
#
#  mx_id      :integer(4)      not null
#  otu_id     :integer(4)      not null
#  notes      :text
#  position   :integer(4)
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#  id         :integer(4)      not null, primary key
#

class MxesOtu < ActiveRecord::Base
  has_standard_fields
  belongs_to :mx
  belongs_to :otu
  acts_as_list :scope => :mx

  validates_uniqueness_of 'otu_id', :scope => 'mx_id'
  scope :ordered_by_otu_name, :order => 'otus.matrix_name ASC, otus.name ASC', :include => :otu

  # so we can reorder, i.e. Mx.mxes_otu will always be ordered by position
  scope :from_mx, lambda {|*args| {:conditions => ["mxes_otus.mx_id = ?", args.first || -1] }} # useful in refs case

end
