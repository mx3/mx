
class ProjsRef < ActiveRecord::Base
  belongs_to :proj
  belongs_to :ref
  acts_as_list :scope => :proj

  validates_uniqueness_of 'ref_id', :scope => 'proj_id'
  
  scope :ordered_by_ref_cached_display_name, :order => 'refs.cached_display_name ASC', :include => :ref

  # so we can reorder, i.e. Mx.mxes_otu will always be ordered by position
  scope :from_mx, lambda {|*args| {:conditions => ["mxes_otus.mx_id = ?", args.first || -1] }} # useful in refs case

end
