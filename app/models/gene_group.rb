# == Schema Information
# Schema version: 20090930163041
#
# Table name: gene_groups
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  notes      :text
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class GeneGroup < ActiveRecord::Base
  has_standard_fields
  has_and_belongs_to_many :genes

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => 'proj_id'

  def display_name(options = {})
    name
  end
end
