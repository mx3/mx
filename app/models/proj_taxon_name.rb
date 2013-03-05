# == Schema Information
# Schema version: 20090930163041
#
# Table name: projs_taxon_names
#
#  id            :integer(4)      not null, primary key
#  proj_id       :integer(4)      not null
#  taxon_name_id :integer(4)      not null
#  is_public     :boolean(1)      not null
#

class ProjTaxonName < ActiveRecord::Base
  self.table_name = "projs_taxon_names"

  belongs_to :taxon_name
  belongs_to :proj

  validates_presence_of [:taxon_name, :proj]

  def self.combination_exists(proj_id, taxon_id)
      self.find(:first, :conditions => ["proj_id = ? AND taxon_name_id = ?", proj_id, taxon_id])
  end
  
end
