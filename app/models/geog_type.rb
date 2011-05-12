# == Schema Information
# Schema version: 20090930163041
#
# Table name: geog_types
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)
#  feature_class :integer(4)
#

class GeogType < ActiveRecord::Base
  has_many :geogs  
end
