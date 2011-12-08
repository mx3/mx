# == Schema Information
# Schema version: 20090930163041
#
# Table name: data_sources
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     not null
#  mx_id      :integer(4)
#  dataset_id :integer(4)
#  notes      :text
#  ref_id     :integer(4)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class DataSource < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes

  has_many :trees

  belongs_to :dataset, :dependent => :destroy
  belongs_to :ref
  belongs_to :mx

  validates_presence_of :name

  def display_name(options = {})
    name
  end
end
