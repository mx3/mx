# == Schema Information
# Schema version: 20090930163041
#
# Table name: association_supports
#
#  id              :integer(4)      not null, primary key
#  association_id  :integer(4)      not null
#  confidence_id   :integer(4)      not null
#  type            :string(32)
#  ref_id          :integer(4)
#  voucher_lot_id  :integer(4)
#  specimen_id     :integer(4)
#  temp_ref        :text
#  temp_ref_mjy_id :integer(4)
#  setting         :string(32)
#  notes           :text
#  negative        :boolean(1)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

class RefSupport < AssociationSupport
  belongs_to :ref
  validates_presence_of :ref
  
  def display_type
    'reference'
  end
end
