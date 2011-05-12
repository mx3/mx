# == Schema Information
# Schema version: 20090930163041
#
# Table name: taxon_name_status
#
#  id         :integer(4)      not null, primary key
#  status     :string(128)
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class TaxonNameStatus < ActiveRecord::Base
  set_table_name "taxon_name_status"
  has_standard_fields
  has_many :taxon_names
  has_many :taxon_hists

  def display_name(options = {})
    status
  end
  
end
