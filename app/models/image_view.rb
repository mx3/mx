# == Schema Information
# Schema version: 20090930163041
#
# Table name: image_views
#
#  id         :integer(4)      not null, primary key
#  name       :string(64)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#

class ImageView < ActiveRecord::Base
  has_standard_fields
  validates_presence_of :name
  validates_uniqueness_of :name

  def display_name(options = {})
    name
  end
  
end
