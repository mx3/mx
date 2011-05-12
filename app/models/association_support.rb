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

class AssociationSupport < ActiveRecord::Base
  has_standard_fields
  # this class is extended by RefSupport, VoucherLotSupport, and SpecimenSupport
  belongs_to :confidence
  belongs_to :association ## added this
  
  def self.settings # WEIRD this has to remain here!! do not put below validate
    ["unknown", "lab", "field"]
  end
    
  validates_presence_of :confidence
  validates_inclusion_of :setting, :in => settings

end
